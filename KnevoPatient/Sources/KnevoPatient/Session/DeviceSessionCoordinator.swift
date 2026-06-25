import Foundation

protocol DeviceSessionCoordinating {
    func prepareSet(_ config: SetConfig) async throws
    func finishSetAndCollect(setRecordId: UUID) async throws -> SensorBatch?
}

struct NoopDeviceSessionCoordinator: DeviceSessionCoordinating {
    func prepareSet(_: SetConfig) async throws {}

    func finishSetAndCollect(setRecordId _: UUID) async throws -> SensorBatch? {
        nil
    }
}
