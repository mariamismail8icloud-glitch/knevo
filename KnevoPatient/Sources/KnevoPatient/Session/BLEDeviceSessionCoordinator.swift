import Foundation

enum DeviceSessionError: Error, Equatable {
    case wifiAddressUnavailable
    case batchTimeout
}

/// Drives the BLE control plane for one device-assisted set and collects the
/// post-set sensor batch over the WiFi data plane (§3.4, §4).
///
/// `prepareSet` connects (if needed), starts the TCP receiver so its IP+port are
/// ready BEFORE the set runs, re-sends the WiFiConfig with that current IP+port so
/// the device knows where to push the batch, writes the SetConfig, then START.
/// `finishSetAndCollect` writes STOP, awaits the batch (bounded), and stops the
/// receiver. Provisioning (WiFiStatus handshake) stays in T7's flow; here we only
/// refresh the IP+port the device must connect to, because the receiver binds a
/// fresh ephemeral port each set.
@MainActor
final class BLEDeviceSessionCoordinator: DeviceSessionCoordinating {
    private let transport: BLETransport
    private let receiver: SensorReceiving
    private let wifiSSID: String
    private let wifiPassword: String
    private let batchTimeoutSeconds: Double

    private var connected = false

    init(
        transport: BLETransport? = nil,
        receiver: SensorReceiving = SensorDataReceiver(),
        wifiSSID: String = "",
        wifiPassword: String = "",
        batchTimeoutSeconds: Double = 30
    ) {
        self.transport = transport ?? BLETransportFactory.make()
        self.receiver = receiver
        self.wifiSSID = wifiSSID
        self.wifiPassword = wifiPassword
        self.batchTimeoutSeconds = batchTimeoutSeconds
    }

    func prepareSet(_ config: SetConfig) async throws {
        if !connected {
            try await transport.scanAndConnect()
            connected = true
        }

        let endpoint = try await receiver.start()
        guard let ipString = endpoint.localIP,
              let appIP = DeviceConnectionViewModel.ipv4Bytes(ipString)
        else {
            receiver.stop()
            throw DeviceSessionError.wifiAddressUnavailable
        }

        // Refresh where the device should push the batch: the receiver's current
        // IP + freshly-bound ephemeral port (§3.2 reused as the per-set rendezvous).
        let wifiConfig = WiFiConfig(appPort: endpoint.port, appIP: appIP, ssid: wifiSSID, password: wifiPassword)
        try await transport.write(KnevoCodec.encodeWiFiConfig(wifiConfig), to: KnevoGATT.wifiConfigUUID)

        try await transport.write(KnevoCodec.encodeSetConfig(config), to: KnevoGATT.setConfigUUID)
        try await transport.write(KnevoCodec.encodeControl(.start), to: KnevoGATT.controlUUID)
    }

    func finishSetAndCollect(setRecordId _: UUID) async throws -> SensorBatch? {
        defer { receiver.stop() }
        try await transport.write(KnevoCodec.encodeControl(.stop), to: KnevoGATT.controlUUID)
        return try await awaitBatchWithTimeout()
    }

    private func awaitBatchWithTimeout() async throws -> SensorBatch {
        // Race the batch against a timeout. On timeout, `stop()` resolves the
        // pending `awaitBatch()` (it throws `.cancelled`), so the suspension never
        // leaks even with a slow real device.
        let timeoutNanos = UInt64(batchTimeoutSeconds * 1_000_000_000)
        let timeoutTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: timeoutNanos)
            if !Task.isCancelled {
                receiver.stop()
            }
        }
        defer { timeoutTask.cancel() }
        return try await receiver.awaitBatch()
    }
}
