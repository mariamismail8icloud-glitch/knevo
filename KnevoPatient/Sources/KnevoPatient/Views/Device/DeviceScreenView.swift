import SwiftUI

struct DeviceScreenView: View {
    @Environment(DeviceConnectionViewModel.self) private var deviceVM

    @State private var showCalibration = false

    private let accent = Color(red: 0.91, green: 0, blue: 0.49)
    private let ink = Color(red: 0.06, green: 0.09, blue: 0.16)

    /// Pure mapping from hardware state to a friendly label. Kept static so it
    /// can be unit-tested without constructing the view.
    static func statusLabel(for state: DeviceState) -> String {
        switch state {
        case .idle: "IDLE"
        case .running: "RUNNING"
        case .done: "DONE"
        case .fault: "FAULT"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                    if deviceVM.isConnected {
                        connectedContent
                    } else {
                        disconnectedContent
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Device")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCalibration) {
                NavigationStack {
                    CalibrationView(transport: deviceVM.bleTransport) {
                        showCalibration = false
                    }
                }
            }
        }
    }

    // MARK: - Connected

    private var connectedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(accent.opacity(0.85))
                .frame(height: 64)
            Text("Device connected")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(ink)

            statusPanel

            VStack(spacing: 12) {
                Button {
                    Task { await deviceVM.reconnect() }
                } label: {
                    secondaryLabel("Reconnect")
                }
                .disabled(deviceVM.isBusy)
                .opacity(deviceVM.isBusy ? 0.6 : 1)

                Button {
                    showCalibration = true
                } label: {
                    primaryLabel("Calibrate device")
                }
            }
        }
    }

    private var statusPanel: some View {
        VStack(spacing: 12) {
            if let status = deviceVM.deviceStatus {
                statusRow(label: "Status", value: Self.statusLabel(for: status.state))
                statusRow(label: "Battery", value: "\(status.batteryPct)%")
            } else {
                Text("Waiting for device status…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: accent.opacity(0.08), radius: 8)
        .padding(.horizontal)
    }

    private func statusRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(ink)
        }
    }

    // MARK: - Not connected

    private var disconnectedContent: some View {
        VStack(spacing: 24) {
            statusIcon
            Text("No device connected")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(ink)
            if let detail = disconnectedDetail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                Task { await deviceVM.connect() }
            } label: {
                primaryLabel(deviceVM.isBusy ? "Connecting…" : "Find & connect")
            }
            .disabled(deviceVM.isBusy)
            .opacity(deviceVM.isBusy ? 0.6 : 1)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if deviceVM.isBusy {
            ProgressView()
                .scaleEffect(1.6)
                .tint(accent)
                .frame(height: 64)
        } else {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(accent.opacity(0.85))
                .frame(height: 64)
        }
    }

    private var disconnectedDetail: String? {
        if case let .failed(message) = deviceVM.state {
            return message
        }
        return "Make sure your Knevo device is powered on and nearby."
    }

    // MARK: - Building blocks

    private func primaryLabel(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding()
            .background(accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: accent.opacity(0.3), radius: 8)
            .padding(.horizontal)
    }

    private func secondaryLabel(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundStyle(accent)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accent.opacity(0.4), lineWidth: 1)
            )
            .padding(.horizontal)
    }
}

#Preview {
    DeviceScreenView()
        .environment(DeviceConnectionViewModel(transport: MockBLETransport()))
}
