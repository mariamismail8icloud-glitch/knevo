import SwiftUI

@Observable
@MainActor
private final class EnrollmentViewModel {
    var code: String?
    var isLoading = false
    var isRegenerating = false
    var errorMessage: String?

    func fetchCode() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response: EnrollmentCodeResponse = try await APIClient.shared.get(path: "/api/patient/enrollment-code")
            code = response.enrollmentCode
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func regenerateCode() async {
        isRegenerating = true
        errorMessage = nil
        defer { isRegenerating = false }
        do {
            let response: EnrollmentCodeResponse = try await APIClient.shared.post(
                path: "/api/patients/enrollment-code", body: EmptyBody()
            )
            code = response.enrollmentCode
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct EnrollmentCodeResponse: Decodable {
    let enrollmentCode: String
}

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var vm = EnrollmentViewModel()
    @State private var copied = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.992, green: 0.961, blue: 0.976).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        enrollmentCard
                        logoutButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.fetchCode() }
    }

    private var enrollmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enrollment code")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.16))
                Text("Share this code with your physiotherapist to link your account. Generating a new code unlinks any existing doctor.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if vm.isLoading {
                ProgressView().tint(Color(red: 0.91, green: 0, blue: 0.49))
                    .frame(maxWidth: .infinity)
            } else if let code = vm.code {
                HStack(spacing: 12) {
                    Text(code)
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        UIPasteboard.general.string = code
                        copied = true
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            copied = false
                        }
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
                            .font(.title3)
                    }
                }
                .padding(16)
                .background(Color(red: 0.99, green: 0.91, blue: 0.95))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.91, green: 0, blue: 0.49).opacity(0.3), lineWidth: 1)
                )
            }

            if let err = vm.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red)
            }

            Button {
                Task { await vm.regenerateCode() }
            } label: {
                Group {
                    if vm.isRegenerating {
                        ProgressView().tint(.white)
                    } else {
                        Label("Generate new code", systemImage: "arrow.clockwise")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(Color(red: 0.91, green: 0, blue: 0.49))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(vm.isLoading || vm.isRegenerating)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(red: 0.94, green: 0.84, blue: 0.91), lineWidth: 1)
        )
    }

    private var logoutButton: some View {
        Button {
            authVM.logout()
        } label: {
            Text("Sign out")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color(red: 0.94, green: 0.84, blue: 0.91))
        .foregroundStyle(Color(red: 0.91, green: 0, blue: 0.49))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
