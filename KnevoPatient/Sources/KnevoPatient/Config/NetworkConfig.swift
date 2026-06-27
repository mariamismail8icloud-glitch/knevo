import Foundation

enum NetworkConfig {
    static let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        // Default: the deployed demo server over TLS. For local development,
        // set API_BASE_URL in Info.plist (e.g. http://127.0.0.1:8080) to override.
        return "https://knevo.appscorner.com"
    }()
}
