import Foundation

struct PatientSignupRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let name: String
    var phone: String?
    var gender: String?
    var birthDate: String?
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var consentGiven: Bool = true
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let userId: String
    let role: String
    let enrollmentCode: String?
    let accessToken: String
    let refreshToken: String
}
