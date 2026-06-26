import SwiftUI

struct WiFiProvisioningView: View {
    var viewModel: DeviceConnectionViewModel

    @State private var ssid = ""
    @State private var password = ""

    private let accent = Color(red: 0.91, green: 0, blue: 0.49)
    private let ink = Color(red: 0.06, green: 0.09, blue: 0.16)

    var body: some View {
        ZStack {
            Color(red: 0.992, green: 0.961, blue: 0.976)
                .ignoresSafeArea()

            if viewModel.state == .provisioned {
                successState
            } else {
                formState
            }
        }
        .navigationTitle("WiFi Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter the WiFi network your device should use to upload session data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                KnevoTextField(title: "Network name (SSID)", text: $ssid)
                KnevoSecureField(title: "Password", text: $password)

                if case let .failed(message) = viewModel.state {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.leading)
                }

                provisionButton
            }
            .padding()
        }
    }

    private var provisionButton: some View {
        Button {
            Task { await viewModel.provision(ssid: ssid, password: password) }
        } label: {
            HStack {
                if viewModel.state == .provisioning {
                    ProgressView().tint(.white)
                }
                Text(viewModel.state == .provisioning ? "Setting up…" : "Provision WiFi")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: accent.opacity(0.3), radius: 8)
        }
        .disabled(isProvisionDisabled)
        .opacity(isProvisionDisabled ? 0.6 : 1)
    }

    private var isProvisionDisabled: Bool {
        viewModel.state == .provisioning || ssid.isEmpty || password.isEmpty
    }

    private var successState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(accent)
            Text("WiFi set up")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(ink)
            Text("Your device is ready to upload session data over WiFi.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        WiFiProvisioningView(viewModel: DeviceConnectionViewModel(transport: MockBLETransport()))
    }
}
