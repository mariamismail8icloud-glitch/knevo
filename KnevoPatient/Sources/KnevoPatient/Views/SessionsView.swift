import SwiftUI

@Observable
@MainActor
private final class SessionHistoryViewModel {
    var sessions: [SessionResponse] = []
    var isLoading = false
    var errorMessage: String?

    func fetchSessions() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            sessions = try await APIClient.shared.get(path: "/api/patient/sessions")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SessionsView: View {
    @State private var viewModel = SessionHistoryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976).ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Color(red: 0.91, green: 0, blue: 0.49))
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionList
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await viewModel.fetchSessions() }
        }
        .task { await viewModel.fetchSessions() }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 48))
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.4))
            Text("No sessions yet")
                .font(.title3).fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            Text("Start a session from the Home tab to see your history here.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.sessions) { session in
                    SessionRowView(session: session)
                }
            }
            .padding()
        }
    }
}

private struct SessionRowView: View {
    let session: SessionResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                    if let duration = durationText {
                        Text(duration)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                StatusBadge(status: session.status)
            }

            Divider()

            HStack(spacing: 20) {
                if let painBefore = session.painBefore {
                    metricView(label: "Pain before", value: "\(painBefore)/10")
                }
                if let painAfter = session.painAfter {
                    metricView(label: "Pain after", value: "\(painAfter)/10")
                }
                if let sets = session.setRecords, !sets.isEmpty {
                    metricView(label: "Sets", value: "\(sets.count)")
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1)
        )
    }

    private var formattedDate: String {
        guard let raw = session.startedAt,
              let date = ISO8601DateFormatter().date(from: raw) else {
            return "Session"
        }
        return date.formatted(.dateTime.day().month(.wide).year().hour().minute())
    }

    private var durationText: String? {
        guard let startRaw = session.startedAt,
              let endRaw = session.endedAt,
              let start = ISO8601DateFormatter().date(from: startRaw),
              let end = ISO8601DateFormatter().date(from: endRaw) else {
            return nil
        }
        let minutes = Int(end.timeIntervalSince(start) / 60)
        return "\(minutes) min"
    }

    private func metricView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
        }
    }
}

private struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status.uppercased() {
        case "COMPLETED": return .green
        case "STOPPED":   return .orange
        case "ACTIVE":    return Color(red: 0.91, green: 0, blue: 0.49)
        default:          return .secondary
        }
    }

    var body: some View {
        Text(status.capitalized)
            .font(.caption2).fontWeight(.bold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
