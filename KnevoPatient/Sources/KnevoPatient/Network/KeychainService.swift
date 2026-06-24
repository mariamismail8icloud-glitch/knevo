import Foundation
import Security

struct StoredTokens {
    let accessToken: String?
    let refreshToken: String?
    let userId: String?
}

struct KeychainService {
    private static let accessTokenKey = "com.knevo.patient.accessToken"
    private static let refreshTokenKey = "com.knevo.patient.refreshToken"
    private static let userIdKey = "com.knevo.patient.userId"

    static func save(accessToken: String, refreshToken: String, userId: String) {
        set(accessToken, forKey: accessTokenKey)
        set(refreshToken, forKey: refreshTokenKey)
        set(userId, forKey: userIdKey)
    }

    static func loadTokens() -> StoredTokens {
        StoredTokens(
            accessToken: get(accessTokenKey),
            refreshToken: get(refreshTokenKey),
            userId: get(userIdKey)
        )
    }

    static func clear() {
        delete(accessTokenKey)
        delete(refreshTokenKey)
        delete(userIdKey)
    }

    private static func set(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func get(_ key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(_ key: String) {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: key]
        SecItemDelete(query as CFDictionary)
    }
}
