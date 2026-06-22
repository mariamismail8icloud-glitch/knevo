import SwiftUI

struct SignupFlowView: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss
    @State private var step = 1

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case 1:
                    SignupStep1View(onNext: { step = 2 })
                case 2:
                    SignupStep2View(onNext: { step = 3 }, onBack: { step = 1 })
                case 3:
                    SignupStep3View(onSubmit: {
                        Task {
                            await authVM.signup()
                            if authVM.isAuthenticated {
                                step = 4
                            }
                        }
                    }, onBack: { step = 2 })
                case 4:
                    SignupStep4View(onDone: { dismiss() })
                default:
                    EmptyView()
                }
            }
            .environment(authVM)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if step > 1 && step < 4 {
                        Button("Back") { step -= 1 }
                            .foregroundStyle(Color(hex: "#E8007D"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if step < 4 {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(Color(hex: "#64748b"))
                    }
                }
            }
        }
    }
}

struct SignupStep1View: View {
    @Environment(AuthViewModel.self) private var authVM
    let onNext: () -> Void

    var body: some View {
        @Bindable var vm = authVM // swiftlint:disable:this identifier_name
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepHeader(step: 1, total: 3, title: "Account details")

                if let err = authVM.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(.red)
                        .padding(12).background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                KnevoTextField(title: "Username", text: $vm.signupUsername)
                KnevoTextField(title: "Email", text: $vm.signupEmail, keyboardType: .emailAddress)
                KnevoSecureField(title: "Password", text: $vm.signupPassword)
                KnevoSecureField(title: "Confirm password", text: $vm.signupConfirmPassword)

                KnevoButton(title: "Continue") {
                    authVM.errorMessage = nil
                    guard !authVM.signupUsername.isEmpty, !authVM.signupEmail.isEmpty,
                          !authVM.signupPassword.isEmpty else {
                        authVM.errorMessage = "Please fill in all fields"
                        return
                    }
                    guard authVM.signupPassword == authVM.signupConfirmPassword else {
                        authVM.errorMessage = "Passwords don't match"
                        return
                    }
                    onNext()
                }
            }
            .padding(24)
        }
        .background(Color(hex: "#fdf5f9"))
    }
}

struct SignupStep2View: View {
    @Environment(AuthViewModel.self) private var authVM
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        @Bindable var vm = authVM // swiftlint:disable:this identifier_name
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepHeader(step: 2, total: 3, title: "Personal details")
                KnevoTextField(title: "Full name", text: $vm.signupName)
                KnevoTextField(title: "Phone (optional)", text: $vm.signupPhone, keyboardType: .phonePad)
                KnevoTextField(title: "Emergency contact name (optional)", text: $vm.signupEmergencyName)
                KnevoTextField(
                    title: "Emergency contact phone (optional)",
                    text: $vm.signupEmergencyPhone,
                    keyboardType: .phonePad
                )
                KnevoButton(title: "Continue") {
                    guard !authVM.signupName.isEmpty else {
                        authVM.errorMessage = "Please enter your full name"
                        return
                    }
                    onNext()
                }
            }
            .padding(24)
        }
        .background(Color(hex: "#fdf5f9"))
    }
}

struct SignupStep3View: View {
    @Environment(AuthViewModel.self) private var authVM
    let onSubmit: () -> Void
    let onBack: () -> Void

    var body: some View {
        @Bindable var vm = authVM // swiftlint:disable:this identifier_name
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepHeader(step: 3, total: 3, title: "Consent")
                VStack(alignment: .leading, spacing: 12) {
                    Text("Terms and Consent")
                        .font(.headline).foregroundStyle(Color(hex: "#0f172a"))
                    Text(
                        "By registering, you agree to use this app for rehabilitation purposes under medical supervision. " +
                        "Your session data will be shared with your assigned physiotherapist."
                    )
                    .font(.body).foregroundStyle(Color(hex: "#64748b"))
                }
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#f0d6e8")))

                Toggle(isOn: $vm.consentGiven) {
                    Text("I agree to the terms").font(.subheadline).foregroundStyle(Color(hex: "#0f172a"))
                }
                .tint(Color(hex: "#E8007D"))

                if let err = authVM.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(.red)
                }

                KnevoButton(
                    title: authVM.isLoading ? "Creating account…" : "Create account",
                    disabled: !authVM.consentGiven || authVM.isLoading
                ) {
                    onSubmit()
                }
            }
            .padding(24)
        }
        .background(Color(hex: "#fdf5f9"))
    }
}

struct SignupStep4View: View {
    @Environment(AuthViewModel.self) private var authVM
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color(hex: "#E8007D"))
            VStack(spacing: 8) {
                Text("Account created!").font(.title2.bold()).foregroundStyle(Color(hex: "#0f172a"))
                Text("Share this code with your physiotherapist to link your account")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(hex: "#64748b"))
            }
            if let code = authVM.enrollmentCode {
                HStack(spacing: 16) {
                    Text(code)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#E8007D"))
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(Color(hex: "#E8007D"))
                    }
                }
                .padding(20)
                .background(Color(hex: "#fce8f3"))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            KnevoButton(title: "Go to Home") { onDone() }
                .padding(.horizontal, 24)
            Spacer()
        }
        .background(Color(hex: "#fdf5f9").ignoresSafeArea())
    }
}

struct StepHeader: View {
    let step: Int
    let total: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(step) of \(total)").font(.caption).foregroundStyle(Color(hex: "#64748b"))
            Text(title).font(.title2.bold()).foregroundStyle(Color(hex: "#0f172a"))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#f0d6e8")).frame(height: 4)
                    RoundedRectangle(cornerRadius: 4).fill(Color(hex: "#E8007D"))
                        .frame(width: geo.size.width * CGFloat(step) / CGFloat(total), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

struct KnevoButton: View {
    let title: String
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(disabled ? Color(hex: "#E8007D").opacity(0.4) : Color(hex: "#E8007D"))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .disabled(disabled)
    }
}
