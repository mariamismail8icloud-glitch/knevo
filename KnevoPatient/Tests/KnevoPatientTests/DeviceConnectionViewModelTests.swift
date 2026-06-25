import Foundation
@testable import KnevoPatient
import Testing

@Suite("DeviceConnectionViewModel")
@MainActor
struct DeviceConnectionViewModelTests {
    @Test("connect() reaches connected state with the mock device")
    func connectSucceeds() async {
        let mock = MockBLETransport()
        let viewModel = DeviceConnectionViewModel(transport: mock)

        await viewModel.connect()

        #expect(viewModel.state == .connected)
    }

    @Test("provision() happy path reaches provisioned and forwards the WiFi credentials")
    func provisionHappyPath() async {
        let mock = MockBLETransport()
        let viewModel = DeviceConnectionViewModel(transport: mock)

        await viewModel.connect()
        await viewModel.provision(ssid: "ClinicWiFi", password: "s3cret-pass")

        #expect(viewModel.state == .provisioned)
        #expect(mock.lastWiFiConfig?.ssid == "ClinicWiFi")
        #expect(mock.lastWiFiConfig?.password == "s3cret-pass")
        #expect(mock.lastWiFiConfig?.appPort != 0)
    }

    @Test("provision() failure path reaches failed with a user-friendly message")
    func provisionFailurePath() async {
        let mock = MockBLETransport(shouldFailProvisioning: true, provisioningErrorCode: 1)
        let viewModel = DeviceConnectionViewModel(transport: mock)

        await viewModel.connect()
        await viewModel.provision(ssid: "ClinicWiFi", password: "wrong-pass")

        guard case let .failed(message) = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)
        #expect(!message.lowercased().contains("error"))
    }

    @Test("provision() before connecting fails with guidance")
    func provisionRequiresConnection() async {
        let mock = MockBLETransport()
        let viewModel = DeviceConnectionViewModel(transport: mock)

        await viewModel.provision(ssid: "ClinicWiFi", password: "pass")

        guard case let .failed(message) = viewModel.state else {
            Issue.record("expected .failed, got \(viewModel.state)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test("a 3-byte DeviceStatus notification updates deviceStatus after connect()")
    func deviceStatusObserved() async {
        let mock = MockBLETransport()
        let viewModel = DeviceConnectionViewModel(transport: mock)

        await viewModel.connect()
        #expect(viewModel.deviceStatus == nil)

        // Emit a START control; the mock yields a 3-byte running DeviceStatus.
        try? await mock.write(KnevoCodec.encodeControl(.start), to: KnevoGATT.controlUUID)

        // Let the shared observer drain the yielded notification.
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.deviceStatus?.state == .running)
        #expect(viewModel.deviceStatus?.batteryPct == 87)
    }

    @Test("reconnect() reaches connected state again against a fresh mock")
    func reconnectSucceeds() async {
        // reconnect() builds a fresh transport via BLETransportFactory.make();
        // force the mock so this runs without real CoreBluetooth in the Simulator.
        setenv("KNEVO_MOCK_BLE", "1", 1)
        defer { unsetenv("KNEVO_MOCK_BLE") }

        let mock = MockBLETransport()
        let viewModel = DeviceConnectionViewModel(transport: mock)

        await viewModel.connect()
        #expect(viewModel.state == .connected)

        await viewModel.reconnect()

        #expect(viewModel.state == .connected)
    }
}
