import Foundation
import SwiftUI

enum SessionPhase {
    case prePainCheck
    case running
    case setActive(setIndex: Int)
    case restTimer(setIndex: Int)
    case postSession
    case summary
}

@Observable
@MainActor
final class SessionViewModel {
    var phase: SessionPhase = .prePainCheck
    var session: SessionResponse?
    var currentSetRecord: SetRecordResponse?
    var errorMessage: String?
    var isLoading = false

    // Pain inputs
    var prePainLevel: Int = 0
    var postPainLevel: Int = 0
    var inSetPainLevel: Int = 0
    var setFeedback: String = ""

    // Timer
    var secondsElapsed: Int = 0
    var timerActive = false

    /// Lightweight surface for the last device-assisted upload (nil when none).
    var lastUploadedSampleCount: Int?

    private var timerTask: Task<Void, Never>?

    let plan: ActivePlan
    private let deviceCoordinator: DeviceSessionCoordinating
    private let uploadService: SensorUploadService

    init(
        plan: ActivePlan,
        deviceCoordinator: DeviceSessionCoordinating = NoopDeviceSessionCoordinator(),
        uploadService: SensorUploadService = SensorUploadService()
    ) {
        self.plan = plan
        self.deviceCoordinator = deviceCoordinator
        self.uploadService = uploadService
    }

    func startSession() async {
        guard prePainLevel < 7 else {
            errorMessage = "Your pain level is too high to start a session. Please rest and consult your doctor."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            session = try await APIClient.shared.post(
                path: "/api/sessions/start",
                body: StartSessionRequest(configId: plan.id, painBefore: prePainLevel)
            )
            phase = .running
        } catch {
            errorMessage = "Failed to start session: \(error.localizedDescription)"
        }
    }

    func startSet(at index: Int) async {
        guard let session, index < plan.sets.count else { return }
        let setConfig = plan.sets[index]
        isLoading = true
        defer { isLoading = false }
        do {
            let record: SetRecordResponse = try await APIClient.shared.post(
                path: "/api/sessions/\(session.id)/start-set",
                body: StartSetRequest(therapySetConfigId: setConfig.id)
            )
            currentSetRecord = record
            if setConfig.deviceAssisted {
                await prepareDevice(for: setConfig, setRecordId: record.id)
            }
            secondsElapsed = 0
            timerActive = true
            startTimer()
            phase = .setActive(setIndex: index)
        } catch {
            errorMessage = "Failed to start set."
        }
    }

    /// Best-effort device prep. The set runs autonomously: any BLE/WiFi failure
    /// surfaces a friendly message but MUST NOT block the HTTP set state machine.
    func prepareDevice(for setConfig: TherapySetInfo, setRecordId: String) async {
        guard let recordUUID = UUID(uuidString: setRecordId) else {
            errorMessage = "Couldn't start the device for this set. The session will continue without it."
            return
        }
        let config = SetConfig(
            setRecordId: recordUUID,
            durationS: UInt16((setConfig.durationMin ?? 0) * 60),
            maxSpeed: Float(plan.maxSpeed ?? 0),
            maxExtensionAngleDeg: Float(plan.maxExtensionAngleDeg ?? 0),
            maxFlexionAngleDeg: Float(plan.maxFlexionAngleDeg ?? 0)
        )
        do {
            try await deviceCoordinator.prepareSet(config)
        } catch {
            errorMessage = "Couldn't start the device for this set. The session will continue without it."
        }
    }

    func stopSet(at index: Int) async {
        guard let session, let record = currentSetRecord else { return }
        stopTimer()
        isLoading = true
        defer { isLoading = false }
        do {
            let _: SetRecordResponse = try await APIClient.shared.post(
                path: "/api/sessions/\(session.id)/stop-set",
                body: StopSetRequest(
                    therapySetRecordId: record.id,
                    painLevel: inSetPainLevel,
                    feedback: setFeedback
                )
            )
            if index < plan.sets.count, plan.sets[index].deviceAssisted {
                await collectAndUpload(sessionId: session.id, setRecordId: record.id)
            }
            currentSetRecord = nil
            inSetPainLevel = 0
            setFeedback = ""
            let nextIndex = index + 1
            if nextIndex < plan.sets.count {
                let restSecs = plan.sets[index].restDurationMin.map { $0 * 60 } ?? 120
                if restSecs > 0 {
                    secondsElapsed = restSecs
                    startRestTimer()
                    phase = .restTimer(setIndex: index)
                } else {
                    phase = .running
                }
            } else {
                phase = .postSession
            }
        } catch {
            errorMessage = "Failed to stop set."
        }
    }

    /// Best-effort post-set batch collection + upload. Errors surface a friendly
    /// message but MUST NOT block the set/session state machine (autonomy + isolation).
    func collectAndUpload(sessionId: String, setRecordId: String) async {
        guard let sessionUUID = UUID(uuidString: sessionId),
              let recordUUID = UUID(uuidString: setRecordId)
        else {
            errorMessage = "Couldn't save device data for this set."
            return
        }
        do {
            guard let batch = try await deviceCoordinator.finishSetAndCollect(setRecordId: recordUUID) else {
                return
            }
            let inserted = try await uploadService.upload(
                sessionId: sessionUUID,
                setRecordId: recordUUID,
                samples: batch.samples
            )
            lastUploadedSampleCount = inserted
        } catch {
            errorMessage = "Couldn't save device data for this set."
        }
    }

    func reportPainButton(painLevel: Int) async {
        guard let session else { return }
        isLoading = true
        stopTimer()
        defer { isLoading = false }
        do {
            self.session = try await APIClient.shared.post(
                path: "/api/sessions/\(session.id)/pain-button",
                body: PainButtonRequest(painLevel: painLevel)
            )
            phase = .summary
        } catch {
            errorMessage = "Failed to record pain."
        }
    }

    func completeSession() async {
        guard let session else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.session = try await APIClient.shared.post(
                path: "/api/sessions/\(session.id)/complete",
                body: CompleteSessionRequest(painAfter: postPainLevel)
            )
            phase = .summary
        } catch {
            errorMessage = "Failed to complete session."
        }
    }

    func stopSession() async {
        guard let session else { return }
        stopTimer()
        isLoading = true
        defer { isLoading = false }
        do {
            self.session = try await APIClient.shared.post(
                path: "/api/sessions/\(session.id)/stop",
                body: EmptyBody()
            )
            phase = .summary
        } catch {
            errorMessage = "Failed to stop session."
        }
    }

    func skipRest(nextSetIndex _: Int) {
        stopTimer()
        phase = .running
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled && timerActive {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                secondsElapsed += 1
            }
        }
    }

    private func startRestTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled && secondsElapsed > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                secondsElapsed -= 1
            }
            if !Task.isCancelled {
                phase = .running
            }
        }
    }

    private func stopTimer() {
        timerActive = false
        timerTask?.cancel()
        timerTask = nil
    }

    var formattedTime: String {
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
