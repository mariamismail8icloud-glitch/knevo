import Foundation
import Network

/// In-memory fake `knevo_` device for tests, previews, and Pepper end-to-end runs
/// (the iOS Simulator cannot run CoreBluetooth). It decodes what the app writes,
/// emits the status notifications a real device would, and can push a fabricated
/// sensor batch over TCP so `SensorDataReceiver` receives real bytes (used by T8).
///
/// `BLETransport` is a non-isolated protocol (so the real CoreBluetooth transport
/// can bridge its own queue). This mock matches that contract: mutable state is
/// guarded by a lock, making it `@unchecked Sendable`-safe to call from any actor.
final class MockBLETransport: BLETransport, @unchecked Sendable {
    private let lock = NSLock()

    private var _shouldFailProvisioning: Bool
    private let provisioningErrorCode: UInt8
    private let pushSensorBatchOnStop: Bool
    private let syntheticSampleCount: Int

    private var _lastWiFiConfig: WiFiConfig?
    private var _lastSetConfig: SetConfig?
    private var _lastControl: Control?

    private let statusContinuation: AsyncStream<Data>.Continuation
    let statusUpdates: AsyncStream<Data>

    init(
        shouldFailProvisioning: Bool = false,
        provisioningErrorCode: UInt8 = 1,
        pushSensorBatchOnStop: Bool = false,
        syntheticSampleCount: Int = 100
    ) {
        _shouldFailProvisioning = shouldFailProvisioning
        self.provisioningErrorCode = provisioningErrorCode
        self.pushSensorBatchOnStop = pushSensorBatchOnStop
        self.syntheticSampleCount = syntheticSampleCount
        var continuation: AsyncStream<Data>.Continuation!
        statusUpdates = AsyncStream { continuation = $0 }
        statusContinuation = continuation
    }

    // MARK: - Test accessors (thread-safe)

    var shouldFailProvisioning: Bool {
        get { lock.withLock { _shouldFailProvisioning } }
        set { lock.withLock { _shouldFailProvisioning = newValue } }
    }

    var lastWiFiConfig: WiFiConfig? {
        lock.withLock { _lastWiFiConfig }
    }

    var lastSetConfig: SetConfig? {
        lock.withLock { _lastSetConfig }
    }

    var lastControl: Control? {
        lock.withLock { _lastControl }
    }

    // MARK: - BLETransport

    func scanAndConnect() async throws {
        // A mock device is always "found" and connects instantly.
    }

    func write(_ data: Data, to characteristicUUID: String) async throws {
        switch characteristicUUID.lowercased() {
        case KnevoGATT.wifiConfigUUID.lowercased():
            let config = try decodeWiFiConfig(data)
            lock.withLock { _lastWiFiConfig = config }
            statusContinuation.yield(wifiStatusBytes())
        case KnevoGATT.setConfigUUID.lowercased():
            // SetConfig has no decoder in KnevoCodec; record receipt only.
            break
        case KnevoGATT.controlUUID.lowercased():
            handleControl(data)
        default:
            break
        }
    }

    func read(from characteristicUUID: String) async throws -> Data {
        switch characteristicUUID.lowercased() {
        case KnevoGATT.wifiStatusUUID.lowercased():
            return wifiStatusBytes()
        case KnevoGATT.deviceStatusUUID.lowercased():
            return deviceStatusBytes(state: .idle)
        default:
            return Data()
        }
    }

    func disconnect() {
        statusContinuation.finish()
    }

    // MARK: - Behavior

    private func handleControl(_ data: Data) {
        guard let raw = data.first, let control = Control(rawValue: raw) else { return }
        lock.withLock { _lastControl = control }
        switch control {
        case .start:
            statusContinuation.yield(deviceStatusBytes(state: .running))
        case .stop:
            statusContinuation.yield(deviceStatusBytes(state: .done))
            if pushSensorBatchOnStop {
                pushSensorBatch()
            }
        }
    }

    private func wifiStatusBytes() -> Data {
        let fail = lock.withLock { _shouldFailProvisioning }
        let status: UInt8 = fail ? 1 : 0
        let errorCode: UInt8 = fail ? provisioningErrorCode : 0
        return Data([status, errorCode])
    }

    private func deviceStatusBytes(state: DeviceState) -> Data {
        Data([state.rawValue, 87, 0]) // 87% battery, no fault
    }

    // MARK: - WiFiConfig decode (inverse of KnevoCodec.encodeWiFiConfig, §3.2)

    private func decodeWiFiConfig(_ data: Data) throws -> WiFiConfig {
        let bytes = [UInt8](data)
        guard bytes.count >= 7 else { throw KnevoCodecError.bufferTooShort }
        var offset = 0
        let appPort = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
        offset += 2
        let appIP = Array(bytes[offset ..< offset + 4])
        offset += 4
        let ssidLen = Int(bytes[offset]); offset += 1
        guard bytes.count >= offset + ssidLen + 1 else { throw KnevoCodecError.bufferTooShort }
        let ssid = String(bytes: bytes[offset ..< offset + ssidLen], encoding: .utf8) ?? ""
        offset += ssidLen
        let passLen = Int(bytes[offset]); offset += 1
        guard bytes.count >= offset + passLen else { throw KnevoCodecError.bufferTooShort }
        let password = String(bytes: bytes[offset ..< offset + passLen], encoding: .utf8) ?? ""
        return WiFiConfig(appPort: appPort, appIP: appIP, ssid: ssid, password: password)
    }

    // MARK: - TCP sensor push (data plane, §4)

    private func pushSensorBatch() {
        guard let config = lock.withLock({ _lastWiFiConfig }) else { return }
        let host = config.appIP.map(String.init).joined(separator: ".")
        guard let port = NWEndpoint.Port(rawValue: config.appPort) else { return }
        let setRecordId = lock.withLock { _lastSetConfig?.setRecordId } ?? UUID()
        let samples = Self.syntheticSamples(count: syntheticSampleCount)
        let frame = KnevoCodec.encodeSensorBatch(setRecordId: setRecordId, samples: samples)

        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: port)
        let connection = NWConnection(to: endpoint, using: .tcp)
        connection.stateUpdateHandler = { state in
            if case .ready = state {
                connection.send(content: frame, completion: .contentProcessed { _ in
                    // Leave the socket open briefly so the ACK can arrive, then close.
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 1) { _, _, _, _ in
                        connection.cancel()
                    }
                })
            }
        }
        connection.start(queue: .global())
    }

    static func syntheticSamples(count: Int) -> [SensorSample] {
        (0 ..< count).map { index in
            let phase = Double(index) * 0.05
            return SensorSample(
                timestampUs: Int64(1_719_300_000_000_000 + index * 5000),
                sampleId: index,
                footAxG: sin(phase), footAyG: cos(phase), footAzG: 0.98,
                footGxRadS: 0.01, footGyRadS: 0.0, footGzRadS: -0.01,
                shankAxG: sin(phase) * 0.5, shankAyG: 0.0, shankAzG: 0.9,
                shankGxRadS: 0.0, shankGyRadS: 0.02, shankGzRadS: 0.0,
                thighAxG: 0.0, thighAyG: 0.0, thighAzG: 1.0,
                thighGxRadS: 0.0, thighGyRadS: 0.0, thighGzRadS: 0.0,
                heelFsrRaw: 1000 + (index % 1000), midfootFsrRaw: 200 + (index % 200)
            )
        }
    }
}
