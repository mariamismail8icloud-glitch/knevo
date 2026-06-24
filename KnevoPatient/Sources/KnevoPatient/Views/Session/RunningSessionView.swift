import SwiftUI

struct RunningSessionView: View {
    var viewModel: SessionViewModel
    let dismiss: DismissAction
    @State private var showPainAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button { Task { await viewModel.stopSession() } } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Session in progress")
                    .font(.headline)
                Spacer()
                Button {
                    showPainAlert = true
                } label: {
                    Label("Pain", systemImage: "exclamationmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding()
            .background(.white.opacity(0.9))

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.plan.sets.enumerated()), id: \.element.id) { index, set in
                        Button {
                            Task { await viewModel.startSet(at: index) }
                        } label: {
                            setCard(index: index, set: set)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPainAlert) {
            PainDuringView(viewModel: viewModel)
                .presentationDetents([.medium])
        }
    }

    private func setCard(index: Int, set: TherapySetInfo) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.91, green: 0, blue: 0.49))
                    .frame(width: 36, height: 36)
                Text("\(index + 1)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(set.exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                if let dur = set.durationMin {
                    Text("\(dur) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1))
    }
}
