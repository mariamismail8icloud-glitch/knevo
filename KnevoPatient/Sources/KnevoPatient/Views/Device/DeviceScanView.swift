import SwiftUI

struct DeviceScanView: View {
    @State private var viewModel = DeviceConnectionViewModel()

    private let accent = Color(red: 0.91, green: 0, blue: 0.49)
    private let ink = Color(red: 0.06, green: 0.09, blue: 0.16)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                    statusIcon
                    Text(statusTitle)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(ink)
                    if let detail = statusDetail {
                        Text(detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    Spacer()
                    connectButton
                }
                .padding()
            }
            .navigationTitle("Connect Device")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: connectedBinding) {
                WiFiProvisioningView(viewModel: viewModel)
            }
        }
    }

    private var connectedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isConnected },
            set: { _ in }
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        if viewModel.isBusy {
            ProgressView()
                .scaleEffect(1.6)
                .tint(accent)
                .frame(height: 64)
        } else {
            Image(systemName: iconName)
                .font(.system(size: 56))
                .foregroundStyle(accent.opacity(0.85))
                .frame(height: 64)
        }
    }

    private var iconName: String {
        switch viewModel.state {
        case .failed: "exclamationmark.triangle.fill"
        case .connected, .provisioning, .provisioned: "checkmark.circle.fill"
        default: "wave.3.right.circle.fill"
        }
    }

    private var statusTitle: String {
        switch viewModel.state {
        case .idle: "Connect to your exoskeleton"
        case .scanning: "Searching for your device…"
        case .connecting: "Connecting…"
        case .connected, .provisioning, .provisioned: "Device connected"
        case .failed: "Connection problem"
        }
    }

    private var statusDetail: String? {
        switch viewModel.state {
        case .idle: "Make sure your Knevo device is powered on and nearby."
        case let .failed(message): message
        default: nil
        }
    }

    private var connectButton: some View {
        Button {
            Task { await viewModel.connect() }
        } label: {
            Text(buttonTitle)
                .frame(maxWidth: .infinity)
                .padding()
                .background(accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: accent.opacity(0.3), radius: 8)
        }
        .disabled(viewModel.isBusy)
        .opacity(viewModel.isBusy ? 0.6 : 1)
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .failed: "Try again"
        case .connected, .provisioning, .provisioned: "Reconnect"
        default: "Connect to device"
        }
    }
}

#Preview {
    DeviceScanView()
}
