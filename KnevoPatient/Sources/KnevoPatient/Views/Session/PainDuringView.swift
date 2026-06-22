import SwiftUI

struct PainDuringView: View {
    var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var level: Int = 5

    var body: some View {
        VStack(spacing: 24) {
            Text("How is your pain?")
                .font(.title3)
                .fontWeight(.bold)

            Text("\(level)")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(level >= 7 ? .red : .orange)

            Slider(value: Binding(get: { Double(level) }, set: { level = Int($0) }), in: 0...10, step: 1)
                .tint(level >= 7 ? .red : .orange)

            if level >= 9 {
                Text("Severe pain — session will end and your doctor will be alerted.")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else if level >= 7 {
                Text("High pain — session will end.")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button(level >= 7 ? "End Session" : "Record & Continue") {
                    Task {
                        await viewModel.reportPainButton(painLevel: level)
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(24)
    }
}
