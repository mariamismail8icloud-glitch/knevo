import Testing
@testable import KnevoPatient

@Suite("AuthViewModel")
@MainActor
struct AuthViewModelTests {
    @Test("starts unauthenticated when no keychain tokens")
    func startsUnauthenticated() {
        KeychainService.clear()
        let viewModel = AuthViewModel()
        #expect(viewModel.isAuthenticated == false)
    }

    @Test("passwords must match to signup")
    func passwordsMustMatch() async {
        KeychainService.clear()
        let viewModel = AuthViewModel()
        viewModel.signupUsername = "test"
        viewModel.signupEmail = "t@t.com"
        viewModel.signupPassword = "pass1"
        viewModel.signupConfirmPassword = "pass2"
        viewModel.signupName = "Test"
        viewModel.consentGiven = true
        await viewModel.signup()
        #expect(viewModel.errorMessage == "Passwords don't match")
        #expect(viewModel.isAuthenticated == false)
    }
}
