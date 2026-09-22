import SwiftUI
import AuthenticationServices

struct LoginView: View {
    var onSignIn: (String) -> Void
    var onCreateAccount: (String) -> Void
    var onForgotPassword: (() -> Void)? = nil
    var onAppleSignIn: (() -> Void)? = nil
    var onGoogleSignIn: (() -> Void)? = nil

    @StateObject private var appleAuthManager = AppleAuthManager.shared

    @State private var mode: AuthMode = .signIn
    @State private var fullName = ""
    @State private var email = UserDefaults.standard.string(forKey: "milliProfileEmail") ?? ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var authenticationMessage: String?
    @State private var isSubmitting = false
    @FocusState private var focusedField: Field?

    /// Matches the backend password policy so the button state never promises
    /// something the server will reject.
    private static let minimumPasswordLength = 12

    private enum AuthMode {
        case signIn
        case signUp
    }

    private enum Field {
        case name
        case email
        case password
        case confirmPassword
    }

    private var normalizedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var hasValidEmailShape: Bool {
        let parts = normalizedEmail.split(separator: "@")
        guard parts.count == 2 else { return false }
        return parts[1].contains(".") && !parts[0].isEmpty
    }

    private var canSubmit: Bool {
        guard !isSubmitting else { return false }
        switch mode {
        case .signIn:
            return hasValidEmailShape && !password.isEmpty
        case .signUp:
            return fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
                && hasValidEmailShape
                && password.count >= Self.minimumPasswordLength
                && password == confirmPassword
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                brandHero
                    .padding(.top, 44)
                    .padding(.bottom, 22)

                authModeControl
                    .padding(.bottom, 18)

                VStack(spacing: 12) {
                    if mode == .signUp {
                        credentialField(
                            title: "FULL NAME",
                            icon: "person.fill",
                            isFocused: focusedField == .name
                        ) {
                            TextField("Your name", text: $fullName)
                                .textContentType(.name)
                                .submitLabel(.next)
                                .focused($focusedField, equals: .name)
                                .onSubmit { focusedField = .email }
                        }
                    }

                    credentialField(
                        title: "EMAIL",
                        icon: "envelope.fill",
                        isFocused: focusedField == .email
                    ) {
                        TextField("Email address", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .email)
                            .onSubmit { focusedField = .password }
                    }

                    credentialField(
                        title: "PASSWORD",
                        icon: "lock.fill",
                        isFocused: focusedField == .password
                    ) {
                        HStack(spacing: 8) {
                            Group {
                                if showPassword {
                                    TextField(mode == .signUp ? "Create password" : "Password", text: $password)
                                } else {
                                    SecureField(mode == .signUp ? "Create password" : "Password", text: $password)
                                }
                            }
                            .textContentType(mode == .signUp ? .newPassword : .password)
                            .submitLabel(mode == .signUp ? .next : .go)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                if mode == .signUp {
                                    focusedField = .confirmPassword
                                } else {
                                    submit()
                                }
                            }

                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(MilliColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                    }

                    if mode == .signUp {
                        Text("At least \(Self.minimumPasswordLength) characters with a letter and a number.")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        credentialField(
                            title: "CONFIRM PASSWORD",
                            icon: "checkmark.shield.fill",
                            isFocused: focusedField == .confirmPassword
                        ) {
                            SecureField("Repeat password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .submitLabel(.go)
                                .focused($focusedField, equals: .confirmPassword)
                                .onSubmit(submit)
                        }
                    }
                }

                HStack {
                    Spacer()

                    if mode == .signIn, let onForgotPassword {
                        Button("Forgot password?", action: onForgotPassword)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }
                .padding(.top, 8)

                if let authenticationMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MilliColors.warning)
                            .padding(.top, 1)

                        Text(authenticationMessage)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.top, 12)
                    .accessibilityLabel(authenticationMessage)
                }

                Button(action: submit) {
                    HStack(spacing: 8) {
                        Text(mode == .signIn ? "SIGN IN" : "CREATE ACCOUNT")
                            .font(.custom("Sora-SemiBold", size: 15, relativeTo: .headline))
                            .tracking(0.8)

                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(MilliColors.blackGlass)
                        } else {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                    }
                    .foregroundStyle(canSubmit ? MilliColors.blackGlass : MilliColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                canSubmit
                                ? LinearGradient(
                                    colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.035)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: canSubmit ? MilliColors.cyanGlow.opacity(0.22) : .clear, radius: 10)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .padding(.top, 18)

                alternativeSignIn
                    .padding(.top, 20)

                securityFooter
                    .padding(.top, 24)
                    .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
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

    private var authModeControl: some View {
        HStack(spacing: 4) {
            modeButton(.signIn, title: "SIGN IN")
            modeButton(.signUp, title: "CREATE ACCOUNT")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.black.opacity(0.34))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                }
        )
    }

    private func modeButton(_ target: AuthMode, title: String) -> some View {
        let selected = mode == target

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                mode = target
                authenticationMessage = nil
                password = ""
                confirmPassword = ""
                focusedField = nil
            }
        } label: {
            Text(title)
                .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption2))
                .tracking(0.7)
                .foregroundStyle(selected ? MilliColors.blackGlass : MilliColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? MilliColors.cyanGlow : Color.clear)
                        .shadow(color: selected ? MilliColors.cyanGlow.opacity(0.18) : .clear, radius: 6)
                )
        }
        .buttonStyle(.plain)
    }

    private var brandHero: some View {
        VStack(spacing: 11) {
            MilliWordmark(fontSize: 40, tracking: 7.2)
                .padding(.top, 10)

            Text("Money, Made Intelligent.")
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textSecondary)

            Text(mode == .signIn ? "Welcome back" : "Build your Milli profile")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity)
    }

    private func credentialField<Content: View>(
        title: String,
        icon: String,
        isFocused: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .tracking(0.8)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isFocused ? MilliColors.cyanGlow : MilliColors.textTertiary)
                    .frame(width: 20)

                content()
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .tint(MilliColors.cyanGlow)
            }
            .padding(.horizontal, 13)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.cardBackground, MilliColors.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isFocused ? MilliColors.cyanGlow.opacity(0.45) : Color.white.opacity(0.075),
                                lineWidth: isFocused ? 0.9 : 0.65
                            )
                    }
                    .shadow(color: isFocused ? MilliColors.cyanGlow.opacity(0.10) : .clear, radius: 7)
            )
        }
    }

    @ViewBuilder
    private var alternativeSignIn: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                Text("OR").font(MilliFont.sectionLabel).foregroundStyle(MilliColors.textTertiary)
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            }

            // Native Sign In / Sign Up with Apple
            SignInWithAppleButton(
                mode == .signUp ? .signUp : .signIn,
                onRequest: { request in
                    appleAuthManager.configureAppleRequest(request)
                },
                onCompletion: { result in
                    guard let credential = appleAuthManager.handleAuthorizationCompletion(
                        result: result,
                        isSignUp: mode == .signUp
                    ) else {
                        if let error = appleAuthManager.authErrorMessage {
                            authenticationMessage = error
                        }
                        return
                    }

                    Task { @MainActor in
                        do {
                            try await appleAuthManager.establishFinancialSession(
                                identityToken: credential.identityToken
                            )
                            authenticationMessage = nil
                            if mode == .signUp {
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
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .disabled(!appleAuthManager.isBackendChallengeReady || appleAuthManager.isProcessing)
            .opacity(appleAuthManager.isBackendChallengeReady ? 1 : 0.58)

            if let onGoogleSignIn {
                Button(action: onGoogleSignIn) {
                    HStack(spacing: 8) {
                        Text("G")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MilliColors.cyanGlow)
                        Text(mode == .signUp ? "Sign up with Google" : "Continue with Google")
                    }
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.035))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                            }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var securityFooter: some View {
        HStack(spacing: 7) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
            Text("Credentials are verified by the Milli backend • Session tokens stay in Keychain")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var loginBackground: some View {
        ZStack {
            MilliAmbientBackground()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.065), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.14),
                startRadius: 5,
                endRadius: 230
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

    private func submit() {
        guard canSubmit else { return }
        authenticationMessage = nil
        focusedField = nil

        if mode == .signUp, password != confirmPassword {
            authenticationMessage = "Passwords do not match."
            return
        }

        let credentialEmail = normalizedEmail
        let credentialPassword = password
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSignUp = mode == .signUp
        isSubmitting = true

        Task { @MainActor in
            defer { isSubmitting = false }
            do {
                if isSignUp {
                    try await MilliBackendClient.shared.signUpWithEmail(
                        email: credentialEmail,
                        password: credentialPassword
                    )
                } else {
                    try await MilliBackendClient.shared.signInWithEmail(
                        email: credentialEmail,
                        password: credentialPassword
                    )
                }
            } catch {
                authenticationMessage = error.localizedDescription
                return
            }

            // The password itself never touches local storage; only the
            // profile label and the Keychain session survive this screen.
            password = ""
            confirmPassword = ""

            let defaults = UserDefaults.standard
            defaults.set(credentialEmail, forKey: "milliProfileEmail")
            if isSignUp {
                defaults.set(name, forKey: "milliProfileName")
                defaults.set(true, forKey: "milliHasCreatedAccount")
                onCreateAccount(credentialEmail)
            } else {
                onSignIn(credentialEmail)
            }
        }
    }
}

#Preview {
    LoginView(onSignIn: { _ in }, onCreateAccount: { _ in })
}
