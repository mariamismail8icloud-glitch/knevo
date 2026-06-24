import SwiftUI

struct ActiveSetView: View {
    var viewModel: SessionViewModel
    let setIndex: Int
    @State private var showPain = false

    var currentSet: TherapySetInfo? {
        guard setIndex < viewModel.plan.sets.count else { return nil }
        return viewModel.plan.sets[setIndex]
    }

    var body: some View {
        VStack(spacing: 24) {
            if let set = currentSet {
                Text(set.exercise.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(viewModel.formattedTime)
                    .font(.system(size: 72, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))

                if let instructions = set.exercise.patientInstructions {
                    Text(instructions)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button {
                    showPain = true
                } label: {
                    Label("Pain / Stop", systemImage: "exclamationmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    Task { await viewModel.stopSet(at: setIndex) }
                } label: {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        Text("Finish Set")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.91, green: 0, blue: 0.49))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(24)
        .sheet(isPresented: $showPain) {
            PainDuringView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }
}
