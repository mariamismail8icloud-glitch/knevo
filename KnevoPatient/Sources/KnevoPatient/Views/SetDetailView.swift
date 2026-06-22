import SwiftUI

struct SetDetailView: View {
    let set: TherapySetInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Mode badges
                        HStack(spacing: 8) {
                            if let mode = set.exercise.mode {
                                modeBadge(mode)
                            }
                            if let diff = set.exercise.difficulty {
                                difficultyBadge(diff)
                            }
                            if set.deviceAssisted {
                                badge("Device-assisted", color: Color(red: 0.91, green: 0, blue: 0.49))
                            }
                        }

                        // Stats
                        HStack(spacing: 24) {
                            if let dur = set.durationMin {
                                statCard(label: "Duration", value: "\(dur) min", icon: "clock")
                            }
                            if let rest = set.restDurationMin {
                                statCard(label: "Rest", value: "\(rest) min", icon: "pause.circle")
                            }
                        }

                        // Description
                        if let desc = set.exercise.description {
                            section(title: "About this exercise") {
                                Text(desc)
                                    .font(.body)
                                    .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.55))
                            }
                        }

                        // Patient instructions
                        if let instructions = set.exercise.patientInstructions {
                            section(title: "How to do it") {
                                Text(instructions)
                                    .font(.body)
                                    .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.55))
                            }
                        }

                        // Safety notes
                        if let safety = set.exercise.safetyNotes {
                            section(title: "Safety notes") {
                                Label {
                                    Text(safety)
                                        .font(.body)
                                        .foregroundStyle(Color(red: 0.39, green: 0.45, blue: 0.55))
                                } icon: {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(set.exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                }
            }
        }
    }

    private func modeBadge(_ mode: String) -> some View {
        let label = mode == "DEVICE_ASSISTED" ? "Device" : "Mobile only"
        let color = mode == "DEVICE_ASSISTED"
            ? Color(red: 0.91, green: 0, blue: 0.49)
            : Color.blue
        return badge(label, color: color)
    }

    private func difficultyBadge(_ diff: String) -> some View {
        let color: Color
        switch diff {
        case "BEGINNER": color = .green
        case "INTERMEDIATE": color = .orange
        default: color = .red
        }
        return badge(diff.capitalized, color: color)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statCard(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
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
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1))
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
            content()
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1))
        }
    }
}
