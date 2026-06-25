import Foundation

/// Chooses the BLE transport for the current runtime. Returns `MockBLETransport`
/// when launched with `KNEVO_MOCK_BLE=1` (env) or `-KnevoMockBLE` (launch arg),
/// which lets the whole provisioning flow run in the Simulator and under Pepper.
/// Otherwise returns the real CoreBluetooth-backed transport.
@MainActor
enum BLETransportFactory {
    static func make() -> BLETransport {
        if useMock {
            return MockBLETransport(pushSensorBatchOnStop: true)
        }
        return CoreBluetoothTransport()
    }

    static var useMock: Bool {
        let env = ProcessInfo.processInfo.environment["KNEVO_MOCK_BLE"]
        if env == "1" || env == "true" {
            return true
        }
        return ProcessInfo.processInfo.arguments.contains("-KnevoMockBLE")
    }
}
