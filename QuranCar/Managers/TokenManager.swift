import Foundation
import Security

class TokenManager {
    static let shared = TokenManager()

    private let accessTokenKey = "com.qurancar.accessToken"
    private let idTokenKey = "com.qurancar.idToken"
    private let tokenTypeKey = "com.qurancar.tokenType"
    private let expiresInKey = "com.qurancar.expiresIn"

    private init() {}

    func saveTokens(accessToken: String, idToken: String?, tokenType: String, expiresIn: Int) {
        // Store access token
        saveToKeychain(key: accessTokenKey, value: accessToken)

        // Store ID token if available
        if let idToken = idToken {
            saveToKeychain(key: idTokenKey, value: idToken)
        }

        // Store token type
        saveToKeychain(key: tokenTypeKey, value: tokenType)

        // Store expiration
        let expirationDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        UserDefaults.standard.set(expirationDate.timeIntervalSince1970, forKey: expiresInKey)
    }

    func getAccessToken() -> String? {
        return retrieveFromKeychain(key: accessTokenKey)
    }

    func getIdToken() -> String? {
        return retrieveFromKeychain(key: idTokenKey)
    }

    func getTokenType() -> String? {
        return retrieveFromKeychain(key: tokenTypeKey)
    }

    func isTokenValid() -> Bool {
        guard let expirationTimeInterval = UserDefaults.standard.object(forKey: expiresInKey) as? TimeInterval else {
            return false
        }
        let expirationDate = Date(timeIntervalSince1970: expirationTimeInterval)
        return Date() < expirationDate
    }

    func clearTokens() {
        deleteFromKeychain(key: accessTokenKey)
        deleteFromKeychain(key: idTokenKey)
        deleteFromKeychain(key: tokenTypeKey)
        UserDefaults.standard.removeObject(forKey: expiresInKey)
    }

    // MARK: - Private Keychain Methods

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item if it exists
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("Error saving to Keychain: \(status)")
            return
        }
    }

    private func retrieveFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}