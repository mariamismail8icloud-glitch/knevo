import SwiftUI

struct SessionSummaryView: View {
    var viewModel: SessionViewModel
    let dismiss: DismissAction

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: viewModel.session?.status == "COMPLETED" ? "star.circle.fill" : "stop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(viewModel.session?.status == "COMPLETED" ? Color(red: 0.91, green: 0, blue: 0.49) : .orange)

            Text(viewModel.session?.status == "COMPLETED" ? "Session Saved" : "Session Ended")
                .font(.title2)
                .fontWeight(.bold)

            if let session = viewModel.session {
                VStack(spacing: 12) {
                    statRow(label: "Status", value: session.status.replacingOccurrences(of: "_", with: " "))
                    if let before = session.painBefore {
                        statRow(label: "Pain before", value: "\(before)/10")
                    }
                    if let during = session.painDuring {
                        statRow(label: "Pain during", value: "\(during)/10")
                    }
                    if let after = session.painAfter {
                        statRow(label: "Pain after", value: "\(after)/10")
                    }
                    statRow(label: "Sets completed", value: "\(session.setRecords?.filter { $0.status == "COMPLETED" }.count ?? 0)")
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            Button("Done") { dismiss() }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(red: 0.91, green: 0, blue: 0.49))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(24)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}
