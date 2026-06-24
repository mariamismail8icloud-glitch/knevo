import Foundation

enum NetworkConfig {
    static let baseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        return "http://127.0.0.1:8080"
    }()
}
