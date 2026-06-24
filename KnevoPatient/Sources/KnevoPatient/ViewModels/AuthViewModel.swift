import Foundation
import Observation

@MainActor
@Observable
final class AuthViewModel {
    var isAuthenticated = false
    var enrollmentCode: String?
    var errorMessage: String?
    var isLoading = false

    // Signup step state
    var signupUsername = ""
    var signupEmail = ""
    var signupPassword = ""
    var signupConfirmPassword = ""
    var signupName = ""
    var signupPhone = ""
    var signupGender = ""
    var signupBirthDate = ""
    var signupEmergencyName = ""
    var signupEmergencyPhone = ""
    var consentGiven = false

    // Login state
    var loginEmail = ""
    var loginPassword = ""

    init() {
        let stored = KeychainService.loadTokens()
        if let access = stored.accessToken, !access.isEmpty {
            APIClient.shared.accessToken = access
            isAuthenticated = true
        }
    }

    func signup() async {
        guard signupPassword == signupConfirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let req = PatientSignupRequest(
                username: signupUsername,
                email: signupEmail,
                password: signupPassword,
                name: signupName,
                phone: signupPhone.isEmpty ? nil : signupPhone,
                gender: signupGender.isEmpty ? nil : signupGender,
                emergencyContactName: signupEmergencyName.isEmpty ? nil : signupEmergencyName,
                emergencyContactPhone: signupEmergencyPhone.isEmpty ? nil : signupEmergencyPhone,
                consentGiven: consentGiven
            )
            let response: AuthResponse = try await APIClient.shared.post(path: "/api/auth/signup", body: req)
            APIClient.shared.accessToken = response.accessToken
            KeychainService.save(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                userId: response.userId
            )
            enrollmentCode = response.enrollmentCode
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let req = LoginRequest(email: loginEmail, password: loginPassword)
            let response: AuthResponse = try await APIClient.shared.post(path: "/api/auth/login", body: req)
            APIClient.shared.accessToken = response.accessToken
            KeychainService.save(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken,
                userId: response.userId
            )
            enrollmentCode = response.enrollmentCode
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        KeychainService.clear()
        APIClient.shared.accessToken = nil
        isAuthenticated = false
        enrollmentCode = nil
        loginEmail = ""
        loginPassword = ""
    }
}
