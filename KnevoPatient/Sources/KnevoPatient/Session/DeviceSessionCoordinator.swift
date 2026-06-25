import Foundation

@MainActor
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

/// The slice of `SensorDataReceiver` the coordinator depends on. Extracted so the
/// coordinator can be unit-tested with a fake that delivers a batch without real TCP.
@MainActor
protocol SensorReceiving {
    func start() async throws -> (port: UInt16, localIP: String?)
    func awaitBatch() async throws -> SensorBatch
    func stop()
}

extension SensorDataReceiver: SensorReceiving {}
