import Foundation

@MainActor
final class APIClient {
    static let shared = APIClient()
    private let session = URLSession.shared
    var accessToken: String?

    private init() {}

    private func applyCommonHeaders(to request: inout URLRequest, path: String) {
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if path.hasPrefix("/api/patient/") || path.hasPrefix("/api/messages") {
            if let userId = KeychainService.loadTokens().userId {
                request.setValue(userId, forHTTPHeaderField: "X-User-Id")
            }
        }
    }

    func post<T: Decodable, B: Encodable>(path: String, body: B) async throws -> T {
        let url = URL(string: NetworkConfig.baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyCommonHeaders(to: &request, path: path)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.httpError(0, data)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode, data)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func get<T: Decodable>(path: String) async throws -> T {
        let url = URL(string: NetworkConfig.baseURL + path)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyCommonHeaders(to: &request, path: path)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.httpError(0, data)
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode, data)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: Error, LocalizedError {
    case httpError(Int, Data)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let data):
            // Only trust backend message for codes where it's meaningful (not Spring validation noise)
            if code != 400, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String, !msg.isEmpty {
                return msg
            }
            switch code {
            case 400: return "Invalid request. Please check your details."
            case 401: return "Incorrect email or password."
            case 403: return "You don't have permission to do that."
            case 404: return "Not found."
            case 409: return "An account with that email or username already exists."
            default:  return "Something went wrong. Please try again."
            }
        }
    }
}
