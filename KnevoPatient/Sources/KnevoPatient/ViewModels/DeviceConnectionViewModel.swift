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

    private let transport: BLETransport
    private let receiver: SensorDataReceiver

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

    func connect() async {
        state = .scanning
        do {
            state = .connecting
            try await transport.scanAndConnect()
            state = .connected
        } catch {
            state = .failed(Self.connectMessage(for: error))
        }
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
            try await transport.write(KnevoCodec.encodeWiFiConfig(config), to: KnevoGATT.wifiConfigUUID)

            guard let statusData = await firstStatusUpdate() else {
                state = .failed("The device didn't respond. Move closer and try again.")
                return
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

    // MARK: - Helpers

    private func firstStatusUpdate() async -> Data? {
        for await data in transport.statusUpdates {
            return data
        }
        return nil
    }

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
