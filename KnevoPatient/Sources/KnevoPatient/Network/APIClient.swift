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
        if path.hasPrefix("/api/patient/") {
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
            if let msg = try? JSONDecoder().decode([String: String].self, from: data)["message"] {
                return msg
            }
            return "Request failed (\(code))"
        }
    }
}
