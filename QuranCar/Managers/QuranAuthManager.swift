import Foundation

class QuranAuthManager {
    static let shared = QuranAuthManager()

    private let clientId = Configuration.clientId
    private let clientSecret = Configuration.clientSecret
    private let tokenHost = "https://oauth2.quran.foundation"
    private let scopes = ["content"]

    private init() {}

    func refreshTokenIfNeeded() async {
        // Check if we need a new token
        if !TokenManager.shared.isTokenValid() {
            do {
                let token = try await getNewToken()
                Logger.debug("Successfully obtained new token")
            } catch {
                Logger.error("Error refreshing token: \(error)")
            }
        }
    }

    private func getNewToken() async throws -> String {
        var request = URLRequest(url: URL(string: "\(tokenHost)/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Add Basic Authentication header
        let credentials = "\(clientId):\(clientSecret)"
        Logger.debug("QuranAuthManager: Credentials: \(credentials)")
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        // Use client_credentials grant type
        let parameters = [
            "grant_type": "client_credentials",
            "scope": scopes.joined(separator: " ")
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)

        Logger.debug("QuranAuthManager: Data: \(data)")

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        Logger.debug("QuranAuthManager: Token response: \(tokenResponse)")

        // Save tokens securely
        TokenManager.shared.saveTokens(
            accessToken: tokenResponse.accessToken,
            clientId: self.clientId,
            idToken: tokenResponse.idToken,
            tokenType: tokenResponse.tokenType,
            expiresIn: tokenResponse.expiresIn
        )

        return tokenResponse.accessToken
    }
}

// MARK: - Supporting Types

enum QuranAuthError: Error {
    case invalidURL
    case noData
    case invalidResponse
}

struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let idToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}
