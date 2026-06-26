@testable import KnevoPatient
import Testing

@Suite("DeviceScreenView")
@MainActor
struct DeviceScreenViewTests {
    @Test("statusLabel maps each DeviceState to its friendly uppercase label")
    func statusLabelMapping() {
        #expect(DeviceScreenView.statusLabel(for: .idle) == "IDLE")
        #expect(DeviceScreenView.statusLabel(for: .running) == "RUNNING")
        #expect(DeviceScreenView.statusLabel(for: .done) == "DONE")
        #expect(DeviceScreenView.statusLabel(for: .fault) == "FAULT")
    }
}
