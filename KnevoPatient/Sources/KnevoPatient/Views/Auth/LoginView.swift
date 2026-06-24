import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showSignup = false

    var body: some View {
        @Bindable var vm = authVM // swiftlint:disable:this identifier_name
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#fff5fa"), Color(hex: "#fdf5f9")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 24) {
                        HStack(spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Knevo").font(.headline).foregroundStyle(Color(hex: "#0f172a"))
                                Text("Rehabilitation").font(.caption).foregroundStyle(Color(hex: "#64748b"))
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Welcome back").font(.title.bold()).foregroundStyle(Color(hex: "#0f172a"))
                            Text("Sign in to continue").foregroundStyle(Color(hex: "#64748b"))
                        }

                        if let err = authVM.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(12)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        VStack(spacing: 16) {
                            KnevoTextField(title: "Email", text: $vm.loginEmail, keyboardType: .emailAddress)
                            KnevoSecureField(title: "Password", text: $vm.loginPassword)
                        }

                        Button {
                            authVM.errorMessage = nil
                            guard !authVM.loginEmail.isEmpty, !authVM.loginPassword.isEmpty else {
                                authVM.errorMessage = "Please enter your email and password."
                                return
                            }
                            guard authVM.loginEmail.contains("@") else {
                                authVM.errorMessage = "Please enter a valid email address."
                                return
                            }
                            Task { await authVM.login() }
                        } label: {
                            Group {
                                if authVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In").fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .background(Color(hex: "#E8007D"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .disabled(authVM.isLoading)

                        HStack {
                            Spacer()
                            Button("Create account") { showSignup = true }
                                .foregroundStyle(Color(hex: "#E8007D"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .padding(28)
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color(hex: "#E8007D").opacity(0.08), radius: 30)
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showSignup) {
            SignupFlowView()
                .environment(authVM)
        }
    }
}
