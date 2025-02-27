import Foundation
import AuthenticationServices
import QuranKit

class QuranAuthManager: NSObject {
    static let shared = QuranAuthManager()

    private let clientId = "f84a40d4-ee4f-4765-b8c8-4e67f6c1ca6b"
    private let clientSecret = ".UxR7PBtDfKfefe.bkzmoZrXgP"
    private let tokenHost = "https://prelive-oauth2.quran.foundation"
    private let scopes = ["content"]

    func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
        getClientCredentialsToken(completion: completion)
    }

    private func getClientCredentialsToken(completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "\(tokenHost)/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Add Basic Authentication header
        let credentials = "\(clientId):\(clientSecret)"
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

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(QuranAuthError.noData))
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

                // Save tokens securely
                TokenManager.shared.saveTokens(
                    accessToken: tokenResponse.accessToken,
                    clientId: self.clientId,
                    idToken: tokenResponse.idToken,
                    tokenType: tokenResponse.tokenType,
                    expiresIn: tokenResponse.expiresIn
                )

                completion(.success(tokenResponse.accessToken))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Supporting Types

enum QuranAuthError: Error {
    case invalidURL
    case missingCallbackURL
    case missingAuthCode
    case noData
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
