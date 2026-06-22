import SwiftUI
import Charts

struct PatientProgressView: View {
    @State private var viewModel = ProgressViewModel()

    private var patientId: String {
        KeychainService.loadTokens().userId ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976).ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Color(red: 0.91, green: 0, blue: 0.49))
                } else if let progress = viewModel.progress {
                    progressContent(progress)
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.secondary)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.fetchProgress(patientId: patientId) }
        }
        .task { await viewModel.fetchProgress(patientId: patientId) }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.4))
            Text("No progress data yet")
                .font(.title3).fontWeight(.semibold)
            Text("Complete some sessions to see your progress here.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding()
    }

    @ViewBuilder
    private func progressContent(_ progress: PatientProgress) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Metric cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    metricCard("Completed", value: "\(progress.totalSessionsCompleted)", accent: false)
                    metricCard("Adherence", value: "\(Int(progress.adherenceRate * 100))%", accent: true)
                    metricCard("Prescribed", value: "\(progress.totalSessionsPrescribed)", accent: false)
                    metricCard("Missed", value: "\(progress.missedSessionsCount)", accent: false, warn: progress.missedSessionsCount > 0)
                }

                // Sessions per week chart
                if !progress.sessionsPerWeek.isEmpty {
                    chartCard(title: "Sessions per week") {
                        Chart(progress.sessionsPerWeek) { item in
                            BarMark(
                                x: .value("Week", item.weekLabel),
                                y: .value("Sessions", item.count)
                            )
                            .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                            .cornerRadius(4)
                        }
                        .frame(height: 160)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisValueLabel(orientation: .vertical)
                            }
                        }
                    }
                }

                // Pain trend chart
                if !progress.painTrend.isEmpty {
                    chartCard(title: "Pain level trend") {
                        Chart(progress.painTrend) { item in
                            LineMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("Pain", item.avgPainBefore)
                            )
                            .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                            .symbol(Circle())
                        }
                        .frame(height: 160)
                        .chartYScale(domain: 0...10)
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisValueLabel(orientation: .vertical)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func metricCard(_ label: String, value: String, accent: Bool, warn: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(accent ? Color(red: 0.91, green: 0, blue: 0.49) : warn ? .orange : Color(red: 0.06, green: 0.09, blue: 0.16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(accent ? Color(red: 0.992, green: 0.961, blue: 0.976) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accent ? Color(red: 0.91, green: 0, blue: 0.49).opacity(0.4) : Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1))
    }

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            content()
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1))
    }
}
