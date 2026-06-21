import SwiftUI

struct PatientProgressView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundStyle(Color(red: 232/255, green: 0/255, blue: 125/255))
                Text("Progress")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Your progress trends will appear here")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 253/255, green: 245/255, blue: 249/255))
            .navigationTitle("Progress")
        }
    }
}
