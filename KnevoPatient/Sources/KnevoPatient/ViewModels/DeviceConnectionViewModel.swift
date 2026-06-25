import Foundation

@Observable
@MainActor
final class DeviceConnectionViewModel {
    enum State: Equatable {
        case idle
        case scanning
        case connecting
        case connected
        case provisioning
        case provisioned
        case failed(String)
    }

    private(set) var state: State = .idle

    /// Latest device status (battery, run state, fault) decoded from 3-byte
    /// notifications routed by the shared status observer.
    private(set) var deviceStatus: DeviceStatus?

    private(set) var transport: BLETransport
    private let receiver: SensorDataReceiver

    /// The single consumer of `transport.statusUpdates`. Started when a
    /// connection is established and torn down on `reconnect()`.
    private var observerTask: Task<Void, Never>?

    /// Resolved by the observer when a WiFiStatus (2-byte) payload arrives while
    /// `provision()` is waiting for the handshake.
    private var wifiStatusWaiter: CheckedContinuation<Data, Never>?

    /// Holds a WiFiStatus payload that arrived after the waiter was armed but
    /// before `awaitWiFiStatus()` suspended, so a synchronous device yield isn't
    /// lost. Only meaningful while `wifiStatusArmed` is true.
    private var bufferedWiFiStatus: Data?
    private var wifiStatusArmed = false

    init(
        transport: BLETransport? = nil,
        receiver: SensorDataReceiver = SensorDataReceiver()
    ) {
        self.transport = transport ?? BLETransportFactory.make()
        self.receiver = receiver
    }

    var isBusy: Bool {
        switch state {
        case .scanning, .connecting, .provisioning: true
        default: false
        }
    }

    var isConnected: Bool {
        switch state {
        case .connected, .provisioning, .provisioned: true
        default: false
        }
    }

    /// Read-only access so other components can reuse this connection.
    var bleTransport: BLETransport {
        transport
    }

    func connect() async {
        state = .scanning
        do {
            state = .connecting
            try await transport.scanAndConnect()
            startObserver()
            state = .connected
        } catch {
            state = .failed(Self.connectMessage(for: error))
        }
    }

    /// Tear down the current transport, build a fresh one (the mock's stream
    /// cannot restart after `disconnect()`), restart the observer, then connect
    /// again with the same logic as `connect()`.
    func reconnect() async {
        stopObserver()
        transport.disconnect()
        transport = BLETransportFactory.make()
        await connect()
    }

    /// Build a `WiFiConfig` from the phone's listening IP+port, write it to the
    /// device, then await the WiFiStatus notification (§3.2, §3.3).
    func provision(ssid: String, password: String) async {
        guard isConnected else {
            state = .failed("Connect to your device before setting up WiFi.")
            return
        }
        state = .provisioning
        do {
            let endpoint = try await receiver.start()
            guard let ipString = endpoint.localIP, let appIP = Self.ipv4Bytes(ipString) else {
                state = .failed("Couldn't determine this phone's WiFi address. Check you're connected to WiFi and try again.")
                return
            }
            let config = WiFiConfig(appPort: endpoint.port, appIP: appIP, ssid: ssid, password: password)

            // Arm the waiter BEFORE writing so the observer can route the
            // WiFiStatus the device emits in response. The observer buffers any
            // status that arrives before `awaitWiFiStatus()` suspends, so the
            // synchronous yield the mock does inside write() is never lost.
            let statusData = try await withWiFiStatusArmed {
                try await transport.write(KnevoCodec.encodeWiFiConfig(config), to: KnevoGATT.wifiConfigUUID)
            }

            let status = try KnevoCodec.decodeWiFiStatus(statusData)
            if status.ok {
                state = .provisioned
            } else {
                state = .failed(Self.provisioningMessage(for: status.errorCode))
            }
        } catch let error as SensorReceiverError {
            state = .failed(Self.receiverMessage(for: error))
        } catch {
            state = .failed("WiFi setup failed. Please try again.")
        }
    }

    func reset() {
        state = .idle
    }

    // MARK: - Status observer

    /// Single consumer of `transport.statusUpdates`. Routes each payload by
    /// length: 2 bytes → WiFiStatus (provisioning handshake), 3 bytes →
    /// DeviceStatus (published).
    private func startObserver() {
        stopObserver()
        let stream = transport.statusUpdates
        observerTask = Task { [weak self] in
            for await data in stream {
                guard let self else { return }
                self.route(data)
            }
        }
    }

    private func stopObserver() {
        observerTask?.cancel()
        observerTask = nil
    }

    private func route(_ data: Data) {
        switch data.count {
        case 2:
            guard wifiStatusArmed else { return }
            if let waiter = wifiStatusWaiter {
                wifiStatusWaiter = nil
                wifiStatusArmed = false
                waiter.resume(returning: data)
            } else {
                bufferedWiFiStatus = data
            }
        case 3:
            deviceStatus = try? KnevoCodec.decodeDeviceStatus(data)
        default:
            break
        }
    }

    /// Arm the WiFiStatus waiter, run `body` (the write that triggers the device
    /// response), then await the status the observer routes back. Buffering
    /// handles a status that arrives synchronously inside `body`.
    private func withWiFiStatusArmed(_ body: () async throws -> Void) async rethrows -> Data {
        wifiStatusArmed = true
        bufferedWiFiStatus = nil
        defer {
            wifiStatusArmed = false
            wifiStatusWaiter = nil
            bufferedWiFiStatus = nil
        }
        try await body()
        if let buffered = bufferedWiFiStatus {
            bufferedWiFiStatus = nil
            return buffered
        }
        return await withCheckedContinuation { continuation in
            wifiStatusWaiter = continuation
        }
    }

    // MARK: - Helpers

    static func ipv4Bytes(_ address: String) -> [UInt8]? {
        let parts = address.split(separator: ".")
        guard parts.count == 4 else { return nil }
        var bytes: [UInt8] = []
        for part in parts {
            guard let value = UInt8(part) else { return nil }
            bytes.append(value)
        }
        return bytes
    }

    // MARK: - User-friendly messages

    static func connectMessage(for error: Error) -> String {
        guard let bleError = error as? BLETransportError else {
            return "Couldn't connect to your device. Please try again."
        }
        switch bleError {
        case .poweredOff:
            return "Bluetooth is off. Turn it on in Settings, then try again."
        case .unauthorized:
            return "Knevo needs Bluetooth access. Enable it in Settings, then try again."
        case .unsupported:
            return "This device doesn't support Bluetooth."
        case .deviceNotFound:
            return "No Knevo device found nearby. Make sure it's on and close by."
        case .serviceNotFound, .characteristicNotFound:
            return "Connected device isn't a compatible Knevo exoskeleton."
        case .connectionFailed:
            return "Couldn't connect to your device. Please try again."
        default:
            return "Couldn't connect to your device. Please try again."
        }
    }

    static func provisioningMessage(for errorCode: UInt8) -> String {
        switch errorCode {
        case 1: "The WiFi password was incorrect. Please check it and try again."
        case 2: "That WiFi network wasn't found. Check the network name and try again."
        case 3: "The device timed out joining WiFi. Move closer to the router and try again."
        case 4: "The device joined WiFi but couldn't reach this phone. Make sure both are on the same network."
        default: "WiFi setup failed on the device. Please try again."
        }
    }

    static func receiverMessage(for error: SensorReceiverError) -> String {
        switch error {
        case .localNetworkDenied:
            "Knevo needs Local Network access to receive session data. Enable it in Settings, then try again."
        default:
            "Couldn't start receiving session data. Please try again."
        }
    }
}
