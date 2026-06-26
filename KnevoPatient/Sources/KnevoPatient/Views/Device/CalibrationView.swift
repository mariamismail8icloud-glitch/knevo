import SwiftUI

struct CalibrationView: View {
    @State private var viewModel: CalibrationViewModel
    let onFinish: () -> Void

    private let accent = Color(red: 0.91, green: 0, blue: 0.49)
    private let ink = Color(red: 0.06, green: 0.09, blue: 0.16)

    init(transport: BLETransport, onFinish: @escaping () -> Void) {
        _viewModel = State(initialValue: CalibrationViewModel(transport: transport))
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Color(red: 0.992, green: 0.961, blue: 0.976)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                content
                Spacer()
                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding()
        }
        .navigationTitle("Calibrate Device")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .intro:
            introContent
        case let .instructions(step):
            instructionsContent(step)
        case .countdown:
            countdownContent
        case let .confirm(step):
            confirmContent(step)
        case .done:
            doneContent
        }
    }

    // MARK: - Phases

    private var introContent: some View {
        VStack(spacing: 24) {
            icon("slider.horizontal.3")
            title("Let's calibrate your device")
            detail("Calibration tunes the sensors so your sessions are accurate. It takes two quick steps and only a few seconds each.")
            primaryButton("Start calibration") { viewModel.begin() }
        }
    }

    private func instructionsContent(_ step: CalibrationViewModel.Step) -> some View {
        VStack(spacing: 24) {
            switch step {
            case .unloaded:
                icon("figure.stand")
                title("Step 1 of 2: Lift your foot")
                detail("Slightly lift your foot so its weight is off the device. Hold it there. When you're ready, tap Calibrate and keep still for a few seconds.")
            case .staticWeight:
                icon("figure.stand")
                title("Step 2 of 2: Stand still")
                detail("Place your foot back down, stand up straight, and stay completely still. When you're ready, tap Calibrate and hold the position.")
            }
            primaryButton("Calibrate") { Task { await viewModel.sendCalibration() } }
        }
    }

    private var countdownContent: some View {
        VStack(spacing: 24) {
            Text("\(viewModel.secondsRemaining)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(accent)
                .contentTransition(.numericText())
                .frame(height: 80)
            title("Calibrating…")
            detail("Hold your position until the countdown finishes.")
        }
    }

    private func confirmContent(_ step: CalibrationViewModel.Step) -> some View {
        VStack(spacing: 24) {
            icon("checkmark.circle")
            title("Did that go as instructed?")
            detail(confirmPrompt(step))
            primaryButton("Yes, continue") { viewModel.confirmSuccess() }
            secondaryButton("Retry this step") { viewModel.retry() }
        }
    }

    private var doneContent: some View {
        VStack(spacing: 24) {
            icon("checkmark.seal.fill")
            title("Calibration complete")
            detail("Your device is calibrated and ready for your next session.")
            primaryButton("Done") { onFinish() }
        }
    }

    private func confirmPrompt(_ step: CalibrationViewModel.Step) -> String {
        switch step {
        case .unloaded: "If you kept your foot lifted and stayed still, continue. Otherwise retry this step."
        case .staticWeight: "If you stood straight and stayed still, continue. Otherwise retry this step."
        }
    }

    // MARK: - Building blocks

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 56))
            .foregroundStyle(accent.opacity(0.85))
            .frame(height: 64)
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(ink)
            .multilineTextAlignment(.center)
    }

    private func detail(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: accent.opacity(0.3), radius: 8)
        }
        .padding(.horizontal)
    }

    private func secondaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundStyle(accent)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accent.opacity(0.4), lineWidth: 1)
                )
        }
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        CalibrationView(transport: MockBLETransport()) {}
    }
}
