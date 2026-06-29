//
//  AuthConfig.swift
//  Meditation Builder
//

import Foundation

/// Cognito auth configuration. Replace placeholders after Terraform deploy; SSM runtime override later.
enum AuthConfig {
    static let region = "us-east-1"
    static let userPoolID = "us-east-1_vePlfHnPL"
    static let appClientID = "2pld9j7muda2ipse5f9smhd0kg"
    static let domain = "meditation-builder-staging.auth.us-east-1.amazoncognito.com"
    static let redirectURI = "com.AnimeAI.Meditation-Builder://oauth2/callback"
    static let redirectURLScheme = "com.AnimeAI.Meditation-Builder"
    static let appleIdentityProvider = "SignInWithApple"
    static let scopes = "openid email"

    static var tokenURL: URL {
        URL(string: "https://\(domain)/oauth2/token")!
    }

    static func authorizeURL(codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://\(domain)/oauth2/authorize")!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: appClientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "identity_provider", value: appleIdentityProvider)
        ]
        return components.url!
    }
}
