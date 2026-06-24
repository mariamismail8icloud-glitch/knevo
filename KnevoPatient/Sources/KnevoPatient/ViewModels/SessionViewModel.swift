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

    private var timerTask: Task<Void, Never>?

    let plan: ActivePlan

    init(plan: ActivePlan) {
        self.plan = plan
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
            currentSetRecord = try await APIClient.shared.post(
                path: "/api/sessions/\(session.id)/start-set",
                body: StartSetRequest(therapySetConfigId: setConfig.id)
            )
            secondsElapsed = 0
            timerActive = true
            startTimer()
            phase = .setActive(setIndex: index)
        } catch {
            errorMessage = "Failed to start set."
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

    func skipRest(nextSetIndex: Int) {
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
