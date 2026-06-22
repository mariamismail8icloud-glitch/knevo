import SwiftUI

struct PreSessionPainView: View {
    var viewModel: SessionViewModel

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                Text("How is your pain right now?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Rate your current pain before starting the session.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            painScale

            if viewModel.prePainLevel >= 7 {
                Label("Pain too high — session blocked. Please rest.", systemImage: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else if viewModel.prePainLevel >= 4 {
                Label("Moderate pain — proceed with caution.", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            Button {
                Task { await viewModel.startSession() }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.prePainLevel >= 7 ? "Session Blocked" : "Start Session")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.prePainLevel >= 7 ? Color.gray : Color(red: 0.91, green: 0, blue: 0.49))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.prePainLevel >= 7 || viewModel.isLoading)
        }
        .padding(24)
        .navigationTitle("Pre-Session Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var painScale: some View {
        VStack(spacing: 12) {
            Text("\(viewModel.prePainLevel)")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(painColor)
            Slider(value: Binding(
                get: { Double(viewModel.prePainLevel) },
                set: { viewModel.prePainLevel = Int($0) }
            ), in: 0...10, step: 1)
            .tint(painColor)
            HStack {
                Text("0\nNo pain").font(.caption).multilineTextAlignment(.center)
                Spacer()
                Text("10\nWorst").font(.caption).multilineTextAlignment(.center)
            }
        }
    }

    private var painColor: Color {
        switch viewModel.prePainLevel {
        case 0...3: return .green
        case 4...6: return .orange
        default: return .red
        }
    }
}
