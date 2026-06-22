import SwiftUI

struct RestTimerView: View {
    var viewModel: SessionViewModel
    let setIndex: Int

    var body: some View {
        VStack(spacing: 32) {
            Text("Rest")
                .font(.title)
                .fontWeight(.bold)

            Text(viewModel.formattedTime)
                .font(.system(size: 72, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))

            Text("Next up: Set \(setIndex + 2)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Skip Rest") {
                viewModel.skipRest(nextSetIndex: setIndex + 1)
            }
            .padding()
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(24)
    }
}
