import SwiftUI

/// Reusable card summarizing the shared device connection. Host-agnostic: the
/// host owns navigation and passes `onManage`, so the card works inside any
/// `NavigationStack` (Home and the in-session screen).
struct DeviceStatusCard: View {
    @Environment(DeviceConnectionViewModel.self) private var deviceVM

    /// Invoked when the user taps "Manage". The host opens `DeviceScreenView`
    /// (typically by flipping a `@State` bound to `.navigationDestination`).
    let onManage: () -> Void

    private let accent = Color(red: 0.91, green: 0, blue: 0.49)
    private let ink = Color(red: 0.06, green: 0.09, blue: 0.16)

    /// Pure connection summary so it can be unit-tested without the view.
    static func summary(isConnected: Bool, status: DeviceStatus?) -> String {
        guard isConnected else { return "Not connected" }
        // batteryPct > 100 (device sends 0xFF) = no battery sensing — omit it.
        if let status, status.batteryPct <= 100 {
            return "Knevo Device · Connected · \(status.batteryPct)%"
        }
        return "Knevo Device · Connected"
    }

    var body: some View {
        Button(action: onManage) {
            HStack(spacing: 12) {
                Image(systemName: "wave.3.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(accent.opacity(0.85))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Device")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(ink)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(deviceVM.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(Self.summary(isConnected: deviceVM.isConnected, status: deviceVM.deviceStatus))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("Manage")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(accent)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(accent)
                }
            }
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DeviceStatusCard(onManage: {})
        .environment(DeviceConnectionViewModel(transport: MockBLETransport()))
        .padding()
}
