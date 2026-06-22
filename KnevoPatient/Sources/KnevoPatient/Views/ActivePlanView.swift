import SwiftUI

struct ActivePlanView: View {
    @State private var viewModel = ActivePlanViewModel()
    @State private var selectedSet: TherapySetInfo?
    @State private var showingSession = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(Color(red: 0.91, green: 0, blue: 0.49))
                } else if viewModel.hasNoPlan {
                    emptyState
                } else if let plan = viewModel.plan {
                    planContent(plan)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
            .navigationTitle("My Plan")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.fetchActivePlan()
            }
            .sheet(item: $selectedSet) { set in
                SetDetailView(set: set)
            }
            .sheet(isPresented: $showingSession) {
                if let plan = viewModel.plan {
                    NavigationStack {
                        SessionFlowView(plan: plan)
                    }
                }
            }
        }
        .task {
            await viewModel.fetchActivePlan()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.4))
            Text("No active plan")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            Text("Your doctor hasn't prescribed a therapy plan yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    @ViewBuilder
    private func planContent(_ plan: ActivePlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                scheduleCard(plan)
                Button {
                    showingSession = true
                } label: {
                    Label("Start Session", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.91, green: 0, blue: 0.49))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(red: 0.91, green: 0, blue: 0.49).opacity(0.3), radius: 8)
                }
                setsSection(plan.sets)
            }
            .padding()
        }
    }

    private func scheduleCard(_ plan: ActivePlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active plan", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                Spacer()
                Text(plan.status)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.12))
                    .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Divider()
            HStack(spacing: 24) {
                if let sessionsPerWeek = plan.sessionsPerWeek {
                    statView(label: "Per week", value: "\(sessionsPerWeek)x")
                }
                if let total = plan.totalSessionsNum {
                    statView(label: "Total", value: "\(total) sessions")
                }
                if let schedule = plan.schedule, !schedule.isEmpty {
                    statView(label: "Schedule", value: schedule)
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.3), lineWidth: 1)
        )
    }

    private func statView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
        }
    }

    private func setsSection(_ sets: [TherapySetInfo]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sets (\(sets.count))")
                .font(.headline)
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))

            ForEach(sets) { set in
                let index = sets.firstIndex(where: { $0.id == set.id }) ?? 0
                Button {
                    selectedSet = set
                } label: {
                    setRow(index: index, set: set)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func setRow(index: Int, set: TherapySetInfo) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.91, green: 0, blue: 0.49))
                    .frame(width: 32, height: 32)
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(set.exercise.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                HStack(spacing: 8) {
                    if let dur = set.durationMin {
                        Label("\(dur) min", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let rest = set.restDurationMin {
                        Label("\(rest) min rest", systemImage: "pause.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if set.deviceAssisted {
                        Label("Device", systemImage: "bolt.fill")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1)
        )
    }
}
