//
//  AuthManager.swift
//  Meditation Builder
//

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Security

/// Manages Sign in with Apple → Cognito PKCE token exchange and Keychain-backed session state.
@MainActor
@Observable
final class AuthManager {
    var isAuthenticated = false
    var isGuestBrowsing = false
    var currentUserSub: String?
    var isSigningIn = false
    var lastError: String?

    private(set) var accessToken: String?

    var canAccessMainApp: Bool { isAuthenticated || isGuestBrowsing }

    private enum Keys {
        static let guestBrowsing = "AuthManager.guestBrowsing"
    }

    init() {
        isGuestBrowsing = UserDefaults.standard.bool(forKey: Keys.guestBrowsing)
        Task { await restoreSession() }
    }

    func signInWithApple() async throws {
        isSigningIn = true
        lastError = nil
        defer { isSigningIn = false }

        let verifier = PKCE.generateVerifier()
        let challenge = PKCE.challenge(from: verifier)
        let authURL = AuthConfig.authorizeURL(codeChallenge: challenge)

        let callbackURL = try await WebAuthSessionCoordinator.shared.authenticate(
            url: authURL,
            callbackURLScheme: AuthConfig.redirectURLScheme
        )

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "code" })?
            .value else {
            throw AuthError.missingAuthorizationCode
        }

        let tokens = try await exchangeCodeForTokens(code: code, codeVerifier: verifier)
        try applyTokens(tokens)
        isGuestBrowsing = false
        UserDefaults.standard.set(false, forKey: Keys.guestBrowsing)
        logger.info("Sign in with Apple completed", category: "Auth")
    }

    // TEMP: remove when Apple Developer account is set up
    func signInWithEmailPassword(email: String, password: String) async throws {
        isSigningIn = true
        lastError = nil
        defer { isSigningIn = false }

        let url = URL(string: "https://cognito-idp.\(AuthConfig.region).amazonaws.com/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue("AWSCognitoIdentityProviderService.InitiateAuth", forHTTPHeaderField: "X-Amz-Target")

        let body: [String: Any] = [
            "AuthFlow": "USER_PASSWORD_AUTH",
            "ClientId": AuthConfig.appClientID,
            "AuthParameters": ["USERNAME": email, "PASSWORD": password]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            logger.error("Cognito InitiateAuth error: \(message)", category: "Auth")
            throw AuthError.tokenExchangeFailed(message)
        }

        struct InitiateAuthResponse: Decodable {
            struct AuthResult: Decodable {
                let AccessToken: String?
                let RefreshToken: String?
                let IdToken: String?
            }
            let AuthenticationResult: AuthResult?
        }

        let parsed = try JSONDecoder().decode(InitiateAuthResponse.self, from: data)
        guard let result = parsed.AuthenticationResult else {
            throw AuthError.missingAccessToken
        }

        let tokenResponse = TokenResponse(
            accessToken: result.AccessToken,
            refreshToken: result.RefreshToken,
            idToken: result.IdToken,
            expiresIn: nil
        )
        try applyTokens(tokenResponse)
        isGuestBrowsing = false
        UserDefaults.standard.set(false, forKey: Keys.guestBrowsing)
        logger.info("Email/password sign-in completed", category: "Auth")
    }

    func continueAsGuest() {
        isGuestBrowsing = true
        UserDefaults.standard.set(true, forKey: Keys.guestBrowsing)
        lastError = nil
        logger.info("Continuing as guest", category: "Auth")
    }

    func exitGuestMode() {
        isGuestBrowsing = false
        UserDefaults.standard.set(false, forKey: Keys.guestBrowsing)
    }

    func signOut() {
        isAuthenticated = false
        currentUserSub = nil
        accessToken = nil
        isGuestBrowsing = false
        UserDefaults.standard.set(false, forKey: Keys.guestBrowsing)
        KeychainHelper.deleteAll()
        logger.info("Signed out", category: "Auth")
    }

    func refreshTokenIfNeeded() async throws {
        guard isAuthenticated else { return }

        if let token = accessToken, !JWTDecoder.isExpired(token) {
            return
        }

        guard let refreshToken = KeychainHelper.read(key: KeychainHelper.refreshTokenKey) else {
            clearSession()
            throw AuthError.notAuthenticated
        }

        let tokens = try await refreshTokens(refreshToken: refreshToken)
        try applyTokens(tokens)
    }

    func bearerToken() async throws -> String? {
        if isAuthenticated {
            try await refreshTokenIfNeeded()
        }
        return accessToken
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String, codeVerifier: String) async throws -> TokenResponse {
        let body = TokenRequest(
            grantType: "authorization_code",
            clientID: AuthConfig.appClientID,
            code: code,
            redirectURI: AuthConfig.redirectURI,
            codeVerifier: codeVerifier
        )
        return try await postTokenRequest(body)
    }

    private func refreshTokens(refreshToken: String) async throws -> TokenResponse {
        let body = TokenRequest(
            grantType: "refresh_token",
            clientID: AuthConfig.appClientID,
            refreshToken: refreshToken
        )
        return try await postTokenRequest(body)
    }

    private func postTokenRequest(_ request: TokenRequest) async throws -> TokenResponse {
        var urlRequest = URLRequest(url: AuthConfig.tokenURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = request.formBody.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            logger.error("Cognito token error: \(message)", category: "Auth")
            throw AuthError.tokenExchangeFailed(message)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    private func applyTokens(_ tokens: TokenResponse) throws {
        guard let access = tokens.accessToken else {
            throw AuthError.missingAccessToken
        }

        accessToken = access
        KeychainHelper.save(key: KeychainHelper.accessTokenKey, value: access)

        if let refresh = tokens.refreshToken {
            KeychainHelper.save(key: KeychainHelper.refreshTokenKey, value: refresh)
        }

        if let idToken = tokens.idToken {
            KeychainHelper.save(key: KeychainHelper.idTokenKey, value: idToken)
            currentUserSub = JWTDecoder.subject(from: idToken)
        } else {
            currentUserSub = JWTDecoder.subject(from: access)
        }

        isAuthenticated = true
    }

    private func restoreSession() async {
        guard let storedAccess = KeychainHelper.read(key: KeychainHelper.accessTokenKey) else {
            return
        }

        accessToken = storedAccess

        if JWTDecoder.isExpired(storedAccess) {
            do {
                try await refreshTokenIfNeeded()
            } catch {
                clearSession()
            }
            return
        }

        if let idToken = KeychainHelper.read(key: KeychainHelper.idTokenKey) {
            currentUserSub = JWTDecoder.subject(from: idToken)
        } else {
            currentUserSub = JWTDecoder.subject(from: storedAccess)
        }

        isAuthenticated = true
        isGuestBrowsing = false
        UserDefaults.standard.set(false, forKey: Keys.guestBrowsing)
    }

    private func clearSession() {
        isAuthenticated = false
        currentUserSub = nil
        accessToken = nil
        KeychainHelper.deleteAll()
    }

    enum AuthError: LocalizedError {
        case missingAuthorizationCode
        case missingAccessToken
        case missingCallback
        case sessionStartFailed
        case invalidResponse
        case tokenExchangeFailed(String)
        case notAuthenticated

        var errorDescription: String? {
            switch self {
            case .missingAuthorizationCode: return "Authorization code was not returned."
            case .missingAccessToken: return "Access token was not returned."
            case .missingCallback: return "Authentication callback was missing."
            case .sessionStartFailed: return "Could not start the sign-in session."
            case .invalidResponse: return "Invalid response from the authentication server."
            case .tokenExchangeFailed(let detail): return "Token exchange failed: \(detail)"
            case .notAuthenticated: return "Please sign in to continue."
            }
        }
    }
}

// MARK: - PKCE

private enum PKCE {
    static func generateVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    static func challenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }
}

// MARK: - Token Models

private struct TokenRequest {
    let grantType: String
    let clientID: String
    var code: String?
    var redirectURI: String?
    var codeVerifier: String?
    var refreshToken: String?

    var formBody: String {
        var pairs = [
            "grant_type=\(grantType.urlEncoded)",
            "client_id=\(clientID.urlEncoded)"
        ]
        if let code { pairs.append("code=\(code.urlEncoded)") }
        if let redirectURI { pairs.append("redirect_uri=\(redirectURI.urlEncoded)") }
        if let codeVerifier { pairs.append("code_verifier=\(codeVerifier.urlEncoded)") }
        if let refreshToken { pairs.append("refresh_token=\(refreshToken.urlEncoded)") }
        return pairs.joined(separator: "&")
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let idToken: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - JWT

private enum JWTDecoder {
    static func subject(from jwt: String) -> String? {
        payload(from: jwt)?["sub"] as? String
    }

    static func isExpired(_ jwt: String) -> Bool {
        guard let exp = payload(from: jwt)?["exp"] as? TimeInterval else { return true }
        return Date().timeIntervalSince1970 >= exp - 60
    }

    private static func payload(from jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }
}

// MARK: - Web Auth Session

@MainActor
final class WebAuthSessionCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthSessionCoordinator()

    private var activeSession: ASWebAuthenticationSession?

    func authenticate(url: URL, callbackURLScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                self.activeSession = nil
                if let error = error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: CancellationError())
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: AuthManager.AuthError.missingCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            activeSession = session

            guard session.start() else {
                continuation.resume(throwing: AuthManager.AuthError.sessionStartFailed)
                return
            }
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Keychain

private enum KeychainHelper {
    static let accessTokenKey = "mb.cognito.accessToken"
    static let refreshTokenKey = "mb.cognito.refreshToken"
    static let idTokenKey = "mb.cognito.idToken"
    private static let service = "com.AnimeAI.Meditation-Builder.auth"

    static func save(key: String, value: String) {
        delete(key: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ] as CFDictionary)
    }

    static func deleteAll() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
        delete(key: idTokenKey)
    }
}

// MARK: - Helpers

private extension String {
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
