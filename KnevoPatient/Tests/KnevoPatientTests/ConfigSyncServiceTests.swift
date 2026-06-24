import Testing
@testable import KnevoPatient

@MainActor
struct ConfigSyncServiceTests {
    @Test func initialStateHasNoLastUpdate() {
        let service = ConfigSyncService()
        #expect(service.lastConfigUpdate == nil)
    }

    @Test func disconnectDoesNotCrash() {
        let service = ConfigSyncService()
        service.disconnect() // should be a no-op without crashing
    }
}
