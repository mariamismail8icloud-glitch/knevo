import Foundation
@testable import KnevoPatient
import Testing

@Suite("DeviceSessionFlow")
@MainActor
struct DeviceSessionFlowTests {
    // MARK: - Fakes

    /// In-memory `SensorReceiving` that returns a preset batch (or throws) without TCP.
    private final class FakeReceiver: SensorReceiving {
        var batch: SensorBatch?
        var error: Error?
        private(set) var started = false
        private(set) var stopped = false
        let boundPort: UInt16
        let localIP: String?

        init(batch: SensorBatch? = nil, error: Error? = nil, port: UInt16 = 51000, localIP: String? = "192.168.1.50") {
            self.batch = batch
            self.error = error
            boundPort = port
            self.localIP = localIP
        }

        func start() async throws -> (port: UInt16, localIP: String?) {
            started = true
            return (boundPort, localIP)
        }

        func awaitBatch() async throws -> SensorBatch {
            if let error { throw error }
            guard let batch else { throw DeviceSessionError.batchTimeout }
            return batch
        }

        func stop() {
            stopped = true
        }
    }

    /// Coordinator stub that records calls and can fail, for VM-level isolation tests.
    private final class StubCoordinator: DeviceSessionCoordinating {
        var prepareError: Error?
        var finishResult: SensorBatch?
        var finishError: Error?
        private(set) var preparedConfig: SetConfig?
        private(set) var finishedSetRecordId: UUID?

        func prepareSet(_ config: SetConfig) async throws {
            preparedConfig = config
            if let prepareError { throw prepareError }
        }

        func finishSetAndCollect(setRecordId: UUID) async throws -> SensorBatch? {
            finishedSetRecordId = setRecordId
            if let finishError { throw finishError }
            return finishResult
        }
    }

    private struct FakeError: Error {}

    private func makeConfig(setRecordId: UUID = UUID(), durationS: UInt16 = 600) -> SetConfig {
        SetConfig(
            setRecordId: setRecordId,
            durationS: durationS,
            maxSpeed: 1.5,
            maxExtensionAngleDeg: 10,
            maxFlexionAngleDeg: 90
        )
    }

    private func makeBatch(setRecordId: UUID, count: Int = 5) -> SensorBatch {
        SensorBatch(setRecordId: setRecordId, samples: MockBLETransport.syntheticSamples(count: count))
    }

    // MARK: - Coordinator: prepareSet

    @Test("prepareSet writes SetConfig with the right setRecordId + duration, then START")
    func prepareWritesConfigAndStart() async throws {
        let mock = MockBLETransport()
        let receiver = FakeReceiver()
        let coordinator = BLEDeviceSessionCoordinator(transport: mock, receiver: receiver)

        let recordId = UUID()
        try await coordinator.prepareSet(makeConfig(setRecordId: recordId, durationS: 600))

        #expect(receiver.started)
        #expect(mock.lastSetConfig?.setRecordId == recordId)
        #expect(mock.lastSetConfig?.durationS == 600)
        #expect(mock.lastControl == .start)
    }

    // MARK: - Coordinator: finishSetAndCollect

    @Test("finishSetAndCollect writes STOP, returns the batch, and stops the receiver")
    func finishWritesStopAndCollects() async throws {
        let mock = MockBLETransport()
        let recordId = UUID()
        let receiver = FakeReceiver(batch: makeBatch(setRecordId: recordId))
        let coordinator = BLEDeviceSessionCoordinator(transport: mock, receiver: receiver)

        let batch = try await coordinator.finishSetAndCollect(setRecordId: recordId)

        #expect(mock.lastControl == .stop)
        #expect(batch?.setRecordId == recordId)
        #expect(batch?.samples.count == 5)
        #expect(receiver.stopped)
    }

    @Test("finishSetAndCollect surfaces a timeout when no batch arrives")
    func finishTimesOut() async throws {
        let mock = MockBLETransport()
        let receiver = FakeReceiver(error: DeviceSessionError.batchTimeout)
        let coordinator = BLEDeviceSessionCoordinator(transport: mock, receiver: receiver, batchTimeoutSeconds: 0.2)

        await #expect(throws: DeviceSessionError.batchTimeout) {
            _ = try await coordinator.finishSetAndCollect(setRecordId: UUID())
        }
        #expect(receiver.stopped)
    }

    // MARK: - Control: calibration opcodes

    @Test("MockBLETransport records calibration control writes without pushing a batch")
    func mockRecordsCalibrationControls() async throws {
        let unloaded = MockBLETransport()
        try await unloaded.write(
            KnevoCodec.encodeControl(.calibrateUnloaded),
            to: KnevoGATT.controlUUID
        )
        #expect(unloaded.lastControl == .calibrateUnloaded)

        let staticCal = MockBLETransport()
        try await staticCal.write(
            KnevoCodec.encodeControl(.calibrateStatic),
            to: KnevoGATT.controlUUID
        )
        #expect(staticCal.lastControl == .calibrateStatic)
    }

    // MARK: - VM: upload wiring

    @Test("collectAndUpload calls the uploader with correct sessionId, setRecordId, and samples")
    func uploadReceivesCorrectArguments() async {
        let sessionId = UUID()
        let recordId = UUID()
        let batch = makeBatch(setRecordId: recordId, count: 7)

        let stub = StubCoordinator()
        stub.finishResult = batch

        let captured = CapturedUpload()
        let uploader = SensorUploadService { path, samples in
            await captured.record(path: path, count: samples.count)
            return SensorIngestResponse(inserted: samples.count)
        }

        let viewModel = SessionViewModel(
            plan: makeDeviceAssistedPlan(),
            deviceCoordinator: stub,
            uploadService: uploader
        )

        await viewModel.collectAndUpload(sessionId: sessionId.uuidString, setRecordId: recordId.uuidString)

        #expect(stub.finishedSetRecordId == recordId)
        let path = await captured.path
        let count = await captured.count
        #expect(path == "/api/sessions/\(sessionId.uuidString)/sets/\(recordId.uuidString)/sensor-readings")
        #expect(count == 7)
        #expect(viewModel.lastUploadedSampleCount == 7)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("collectAndUpload does nothing when the coordinator returns no batch")
    func uploadSkippedWhenNoBatch() async {
        let stub = StubCoordinator() // finishResult stays nil
        let uploaderCalled = CapturedUpload()
        let uploader = SensorUploadService { _, samples in
            await uploaderCalled.record(path: "called", count: samples.count)
            return SensorIngestResponse(inserted: 0)
        }
        let viewModel = SessionViewModel(
            plan: makeDeviceAssistedPlan(),
            deviceCoordinator: stub,
            uploadService: uploader
        )

        await viewModel.collectAndUpload(sessionId: UUID().uuidString, setRecordId: UUID().uuidString)

        let path = await uploaderCalled.path
        #expect(path == nil)
        #expect(viewModel.lastUploadedSampleCount == nil)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - VM: error isolation

    @Test("a prepare failure sets errorMessage without throwing (set continues)")
    func prepareFailureIsIsolated() async {
        let stub = StubCoordinator()
        stub.prepareError = FakeError()
        let viewModel = SessionViewModel(plan: makeDeviceAssistedPlan(), deviceCoordinator: stub)

        await viewModel.prepareDevice(for: viewModel.plan.sets[0], setRecordId: UUID().uuidString)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.errorMessage?.lowercased().contains("error") == false)
    }

    @Test("a finish/upload failure sets errorMessage without throwing (session continues)")
    func finishFailureIsIsolated() async {
        let stub = StubCoordinator()
        stub.finishError = FakeError()
        let viewModel = SessionViewModel(plan: makeDeviceAssistedPlan(), deviceCoordinator: stub)

        await viewModel.collectAndUpload(sessionId: UUID().uuidString, setRecordId: UUID().uuidString)

        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.lastUploadedSampleCount == nil)
    }

    // MARK: - VM: stop paths halt the device + upload

    @Test("pain-button stops the brace + collects when a device set is active")
    func painButtonStopsActiveDeviceSet() async {
        let stub = StubCoordinator()
        let recordId = UUID()
        let vm = SessionViewModel(plan: makeDeviceAssistedPlan(), deviceCoordinator: stub)
        vm.session = makeSession()
        vm.currentSetRecord = makeSetRecord(id: recordId)
        vm.phase = .setActive(setIndex: 0)

        // The pain-button network POST may fail in the test env (tolerated); what we
        // assert is that the brace was stopped via the coordinator (STOP + collect).
        await vm.reportPainButton(painLevel: 8)
        await vm.deviceStopTask?.value

        #expect(stub.finishedSetRecordId == recordId)
    }

    @Test("pain-button does not touch the device when no set is active")
    func painButtonNoDeviceWhenNoActiveSet() async {
        let stub = StubCoordinator()
        let vm = SessionViewModel(plan: makeDeviceAssistedPlan(), deviceCoordinator: stub)
        vm.session = makeSession()
        // phase stays .prePainCheck, no currentSetRecord -> no active set

        await vm.reportPainButton(painLevel: 8)
        await vm.deviceStopTask?.value

        #expect(stub.finishedSetRecordId == nil)
    }

    // MARK: - Helpers

    private func makeSession() -> SessionResponse {
        SessionResponse(
            id: UUID().uuidString, patientId: "patient-1", therapyConfigId: "config-1",
            status: "INPROGRESS", startedAt: nil, endedAt: nil,
            painBefore: 2, painDuring: nil, painAfter: nil, setRecords: nil
        )
    }

    private func makeSetRecord(id: UUID) -> SetRecordResponse {
        SetRecordResponse(
            id: id.uuidString, therapySetConfigId: "set-1",
            startDatetime: nil, stopDatetime: nil, painLevel: nil, feedback: nil, status: "IN_PROGRESS"
        )
    }

    private func makeDeviceAssistedPlan() -> ActivePlan {
        ActivePlan(
            id: "config-1",
            patientId: "patient-1",
            issuedById: nil,
            sessionsPerWeek: 3,
            schedule: "MON",
            totalSessionsNum: 12,
            maxFlexionAngleDeg: 90,
            maxExtensionAngleDeg: 10,
            maxSpeed: 1.5,
            status: "INPROGRESS",
            sets: [
                TherapySetInfo(
                    id: "set-1",
                    exercise: ExerciseInfo(
                        id: "ex-1", name: "Device Exercise",
                        category: "ROM", activityType: "STANDING",
                        mode: "DEVICE_ASSISTED", difficulty: "BEGINNER",
                        description: "Test", patientInstructions: "Do it",
                        safetyNotes: nil, defaultSets: 3, defaultReps: 10,
                        defaultRestSeconds: 60, targetJoint: "KNEE"
                    ),
                    deviceAssisted: true,
                    durationMin: 10,
                    restDurationMin: 2,
                    setOrder: 0
                )
            ]
        )
    }
}

/// Actor box capturing the uploader closure's arguments without data races.
private actor CapturedUpload {
    private(set) var path: String?
    private(set) var count: Int?

    func record(path: String, count: Int) {
        self.path = path
        self.count = count
    }
}
