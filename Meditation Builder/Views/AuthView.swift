//
//  AuthView.swift
//  Meditation Builder
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.section) {
                Spacer()

                VStack(spacing: AppTheme.Spacing.large) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(AppTheme.accentColor)
                        .symbolEffect(.pulse, options: .repeating)

                    VStack(spacing: AppTheme.Spacing.small) {
                        Text(LocalizedStringKey("auth.title"))
                            .font(AppTheme.Typography.titleFont)
                            .foregroundStyle(AppTheme.offWhiteText)

                        Text(LocalizedStringKey("auth.subtitle"))
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundStyle(AppTheme.lightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.extraLarge)
                    }
                }

                Spacer()

                VStack(spacing: AppTheme.Spacing.medium) {
                    SignInWithAppleButtonView {
                        Task { await handleSignIn() }
                    }
                    .frame(height: 50)
                    .disabled(authManager.isSigningIn)

                    Button {
                        authManager.continueAsGuest()
                    } label: {
                        Text(LocalizedStringKey("auth.browse.guest"))
                            .font(AppTheme.Typography.buttonFont)
                            .foregroundStyle(AppTheme.lightGrey)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.medium)
                    }
                    .buttonStyle(.plain)
                    .disabled(authManager.isSigningIn)

                    if authManager.isSigningIn {
                        ProgressView()
                            .tint(AppTheme.accentColor)
                    }

                    if let error = authManager.lastError {
                        Text(error)
                            .font(AppTheme.Typography.captionFont)
                            .foregroundStyle(Color.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.section)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleSignIn() async {
        do {
            try await authManager.signInWithApple()
        } catch is CancellationError {
            return
        } catch {
            authManager.lastError = error.localizedDescription
            logger.error("Sign in failed: \(error)", category: "Auth")
        }
    }
}

// MARK: - ASAuthorizationAppleIDButton

struct SignInWithAppleButtonView: UIViewRepresentable {
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = AppTheme.CornerRadius.button
        button.addTarget(context.coordinator, action: #selector(Coordinator.didTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    final class Coordinator: NSObject {
        var onTap: (() -> Void)?

        init(onTap: @escaping () -> Void) {
            self.onTap = onTap
        }

        @objc func didTap() {
            onTap?()
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthManager())
}
