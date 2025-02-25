import Foundation
import AuthenticationServices
import QuranKit

class QuranAuthManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = QuranAuthManager()

    private let clientId = "f84a40d4-ee4f-4765-b8c8-4e67f6c1ca6b"
    private let clientSecret = ".UxR7PBtDfKfefe.bkzmoZrXgP"
    private let redirectUri = "qurancar://oauth/callback"
    private let tokenHost = "https://prelive-oauth2.quran.foundation"
    private let scopes = ["openid"]
    private let state = "veimvfgqexjicockrwsgcb333o3a"

    private var webAuthSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<String, Error>) -> Void)?

    func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
        self.completionHandler = completion

        // Construct the authorization URL
        var components = URLComponents(string: "\(tokenHost)/oauth2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state)
        ]

        guard let authURL = components.url else {
            completion(.failure(QuranAuthError.invalidURL))
            return
        }

        print("Auth URL: \(authURL)") // For debugging

        webAuthSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "qurancar",
            completionHandler: { [weak self] callbackURL, error in
                if let error = error {
                    print("Auth Error: \(error)") // For debugging
                    self?.completionHandler?(.failure(error))
                    return
                }

                guard let callbackURL = callbackURL else {
                    self?.completionHandler?(.failure(QuranAuthError.missingCallbackURL))
                    return
                }

                print("Callback URL: \(callbackURL)") // For debugging
                self?.handleCallback(url: callbackURL)
            }
        )

        webAuthSession?.presentationContextProvider = self
        webAuthSession?.start()
    }

    private func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            completionHandler?(.failure(QuranAuthError.missingAuthCode))
            return
        }

        print("Got code: \(code)") // For debugging
        exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) {
        var request = URLRequest(url: URL(string: "\(tokenHost)/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Add Basic Authentication header
        let credentials = "\(clientId):\(clientSecret)"
        if let credentialsData = credentials.data(using: .utf8) {
            let base64Credentials = credentialsData.base64EncodedString()
            request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        }

        // Remove client credentials from POST body
        let parameters = [
            "code": code,
            "redirect_uri": redirectUri,
            "grant_type": "authorization_code"
        ]

        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        print("Token request: \(request)") // For debugging
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Request body: \(bodyString)")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Token Error: \(error)") // For debugging
                self?.completionHandler?(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Token Response Status: \(httpResponse.statusCode)") // For debugging
            }

            guard let data = data else {
                self?.completionHandler?(.failure(QuranAuthError.noData))
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Token Response: \(responseString)") // For debugging
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

                // Save tokens securely
                TokenManager.shared.saveTokens(
                    accessToken: tokenResponse.accessToken,
                    idToken: tokenResponse.idToken,
                    tokenType: tokenResponse.tokenType,
                    expiresIn: tokenResponse.expiresIn
                )

                self?.completionHandler?(.success(tokenResponse.accessToken))
            } catch {
                print("Token Decode Error: \(error)") // For debugging
                self?.completionHandler?(.failure(error))
            }
        }.resume()
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
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
