import Foundation

@Observable
@MainActor
final class CalibrationViewModel {
    /// Which calibration step the patient is performing.
    enum Step: Equatable {
        case unloaded // step 1: foot lifted, sensors unloaded
        case staticWeight // step 2: standing still, static weight

        var opcode: Control {
            switch self {
            case .unloaded: .calibrateUnloaded
            case .staticWeight: .calibrateStatic
            }
        }
    }

    /// State machine for the two-step calibration flow.
    enum Phase: Equatable {
        case intro
        case instructions(Step)
        case countdown(Step)
        case confirm(Step)
        case done
    }

    private(set) var phase: Phase = .intro
    private(set) var secondsRemaining: Int = 0
    var errorMessage: String?

    private let transport: BLETransport
    private let countdownSeconds: Int

    init(transport: BLETransport, countdownSeconds: Int = 5) {
        self.transport = transport
        self.countdownSeconds = countdownSeconds
    }

    /// Move from the intro explanation into the first step's instructions.
    func begin() {
        phase = .instructions(.unloaded)
    }

    /// Send the calibration command for the current step, run the local
    /// countdown, then move to the self-assessment confirmation. The countdown
    /// is a UI timer only; the flow never blocks on a device response.
    func sendCalibration() async {
        guard case let .instructions(step) = phase else { return }
        errorMessage = nil
        do {
            try await transport.write(KnevoCodec.encodeControl(step.opcode), to: KnevoGATT.controlUUID)
        } catch {
            errorMessage = "Couldn't send the calibration command. Make sure your device is connected and try again."
            return
        }
        await runCountdown(for: step)
        phase = .confirm(step)
    }

    /// Patient confirms they followed the instructions. Advance to the next
    /// step, or finish after the static-weight step.
    func confirmSuccess() {
        guard case let .confirm(step) = phase else { return }
        switch step {
        case .unloaded: phase = .instructions(.staticWeight)
        case .staticWeight: phase = .done
        }
    }

    /// Patient self-assessment failed. Retry the CURRENT step only.
    func retry() {
        guard case let .confirm(step) = phase else { return }
        phase = .instructions(step)
    }

    private func runCountdown(for step: Step) async {
        phase = .countdown(step)
        secondsRemaining = countdownSeconds
        while secondsRemaining > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            secondsRemaining -= 1
        }
    }
}
