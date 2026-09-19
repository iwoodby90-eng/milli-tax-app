import SwiftUI
import AuthenticationServices

// MARK: - LoginView
// Production authentication is intentionally single-authority:
// Apple proves identity, Milli's backend verifies the signed identity token,
// and only the backend can mint the opaque session used by financial features.
// No local password can unlock a production account.

struct LoginView: View {
    var onSignIn: (String) -> Void
    var onCreateAccount: (String) -> Void

    @StateObject private var appleAuthManager = AppleAuthManager.shared
    @State private var authenticationMessage: String?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                brandHero
                    .padding(.top, 54)

                secureAccessCard
                    .padding(.top, 26)

                appleButton
                    .padding(.top, 18)

                #if DEBUG
                debugAccess
                    .padding(.top, 12)
                #endif

                if let authenticationMessage {
                    errorBanner(authenticationMessage)
                        .padding(.top, 14)
                }

                privacyNote
                    .padding(.top, 22)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .background(loginBackground)
        .preferredColorScheme(.dark)
        .task {
            await appleAuthManager.prepareBackendChallenge()
            if !appleAuthManager.isBackendChallengeReady,
               let message = appleAuthManager.authErrorMessage {
                authenticationMessage = message
            }
        }
    }

    private var brandHero: some View {
        VStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.07))
                    .frame(width: 118, height: 118)
                    .blur(radius: 18)

                Circle()
                    .stroke(MilliColors.cyanGlow.opacity(0.13), lineWidth: 0.8)
                    .frame(width: 92, height: 92)

                ChromeEmblemView(size: 72)
            }

            MilliWordmark(fontSize: 35, tracking: 6.8)

            Text("Money, Made Intelligent.")
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textSecondary)

            Text("Secure access to your financial command center")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
    }

    private var secureAccessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SECURE ACCESS")
                    .font(MilliFont.sectionLabel)
                    .tracking(1.0)
                    .foregroundStyle(MilliColors.cyanGlow)

                Spacer()

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            securityRow(
                icon: "apple.logo",
                title: "Apple verifies your identity",
                detail: "Milli receives a signed identity proof—not your Apple ID password."
            )

            Divider().overlay(Color.white.opacity(0.06))

            securityRow(
                icon: "server.rack",
                title: "The backend authorizes financial access",
                detail: "The app cannot invent a user ID or mint its own banking session."
            )

            Divider().overlay(Color.white.opacity(0.06))

            securityRow(
                icon: "key.fill",
                title: "Session tokens stay in Keychain",
                detail: "Short-lived access and rotating refresh credentials are device-bound."
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            MilliColors.cardBackground,
                            MilliColors.graphiteSurface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.22), lineWidth: 0.8)
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.07), radius: 18, y: 8)
        )
    }

    private func securityRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)

                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var appleButton: some View {
        VStack(spacing: 9) {
            SignInWithAppleButton(
                .continue,
                onRequest: { request in
                    appleAuthManager.configureAppleRequest(request)
                },
                onCompletion: { result in
                    guard let credential = appleAuthManager.handleAuthorizationCompletion(
                        result: result
                    ) else {
                        if let error = appleAuthManager.authErrorMessage {
                            authenticationMessage = error
                        }
                        return
                    }

                    Task { @MainActor in
                        do {
                            let isNewUser = try await appleAuthManager.establishFinancialSession(
                                identityToken: credential.identityToken
                            )
                            authenticationMessage = nil

                            if isNewUser {
                                onCreateAccount(credential.email)
                            } else {
                                onSignIn(credential.email)
                            }
                        } catch {
                            authenticationMessage = error.localizedDescription
                        }
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .disabled(!appleAuthManager.isBackendChallengeReady || appleAuthManager.isProcessing)
            .opacity(appleAuthManager.isBackendChallengeReady ? 1 : 0.56)

            if appleAuthManager.isProcessing {
                HStack(spacing: 7) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MilliColors.cyanGlow)

                    Text("Verifying secure session…")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }
            } else if !appleAuthManager.isBackendChallengeReady {
                HStack(spacing: 7) {
                    ProgressView()
                        .controlSize(.small)
                        .tint(MilliColors.cyanGlow)

                    Text("Preparing secure sign-in…")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
        }
    }

    #if DEBUG
    private var debugAccess: some View {
        Button {
            onSignIn("demo@milli.local")
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "hammer.fill")
                Text("Open DEBUG Demo")
            }
            .font(MilliFont.caption)
            .foregroundStyle(MilliColors.cyanGlow)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open debug demo without financial authorization")
    }
    #endif

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.warning)
                .padding(.top, 1)

            Text(message)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MilliColors.warning.opacity(0.07))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MilliColors.warning.opacity(0.18), lineWidth: 0.7)
                }
        )
    }

    private var privacyNote: some View {
        VStack(spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)

                Text("PRIVATE BY DESIGN")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Text("Bank credentials stay inside Plaid Link. Milli's iOS app never receives your Plaid secret, Column API key, or raw server credentials.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var loginBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.075), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.10),
                startRadius: 5,
                endRadius: 280
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.white.opacity(0.018), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    LoginView(onSignIn: { _ in }, onCreateAccount: { _ in })
}
