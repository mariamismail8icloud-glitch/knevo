import SwiftUI

struct PostSessionView: View {
    var viewModel: SessionViewModel

    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))

            Text("Session complete!")
                .font(.title2)
                .fontWeight(.bold)

            Text("How is your pain now?")
                .font(.headline)

            Text("\(viewModel.postPainLevel)")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.green)

            Slider(value: Binding(
                get: { Double(viewModel.postPainLevel) },
                set: { viewModel.postPainLevel = Int($0) }
            ), in: 0...10, step: 1)
            .tint(.green)

            Button {
                Task { await viewModel.completeSession() }
            } label: {
                HStack {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                    Text("Save Session")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.91, green: 0, blue: 0.49))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.isLoading)
        }
        .padding(24)
    }
}
