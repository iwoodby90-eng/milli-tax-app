import SwiftUI
import Security
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
    @FocusState private var focusedField: Field?

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
        switch mode {
        case .signIn:
            return hasValidEmailShape && password.count >= 8
        case .signUp:
            return fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
                && hasValidEmailShape
                && password.count >= 8
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
                    #if DEBUG
                    if mode == .signIn {
                        Button("Use Demo Account", action: fillDemoCredentials)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    #endif

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

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
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
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.06))
                    .frame(width: 92, height: 92)
                    .blur(radius: 14)

                ChromeEmblemView(size: 68)
            }

            MilliWordmark(fontSize: 34, tracking: 6.4)

            // Brand rule: tagline is not screen copy (30-screen spec, conflict #3).
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
                    if let user = appleAuthManager.handleAuthorizationCompletion(result: result, isSignUp: mode == .signUp) {
                        if mode == .signUp {
                            onCreateAccount(user.email)
                        } else {
                            onSignIn(user.email)
                        }
                    } else if let error = appleAuthManager.authErrorMessage {
                        authenticationMessage = error
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
            Text("Secure biometric & Apple ID authentication • Onboarding data is encrypted")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var loginBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

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

        switch mode {
        case .signIn:
            signIn()
        case .signUp:
            createAccount()
        }
    }

    private func signIn() {
        #if DEBUG
        if normalizedEmail == "ian@milli.local", password == "MilliDemo2026!" {
            onSignIn(normalizedEmail)
            return
        }
        #endif

        guard let storedEmail = UserDefaults.standard.string(forKey: "milliProfileEmail")?.lowercased(),
              storedEmail == normalizedEmail
        else {
            authenticationMessage = "We couldn't find this Milli profile on this device. Create an account to begin first-time setup."
            return
        }

        guard MilliLocalCredentialStore.passwordMatches(password, for: normalizedEmail) else {
            authenticationMessage = "The email or password is incorrect."
            return
        }

        onSignIn(normalizedEmail)
    }

    private func createAccount() {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard password == confirmPassword else {
            authenticationMessage = "Passwords do not match."
            return
        }

        guard MilliLocalCredentialStore.store(password: password, for: normalizedEmail) else {
            authenticationMessage = "Milli couldn't securely save this local sign-in. Please try again."
            return
        }

        let defaults = UserDefaults.standard
        defaults.set(name, forKey: "milliProfileName")
        defaults.set(normalizedEmail, forKey: "milliProfileEmail")
        defaults.set(true, forKey: "milliHasCreatedAccount")

        onCreateAccount(normalizedEmail)
    }

    #if DEBUG
    private func fillDemoCredentials() {
        email = "ian@milli.local"
        password = "MilliDemo2026!"
        authenticationMessage = nil
        focusedField = nil
    }
    #endif
}

private enum MilliLocalCredentialStore {
    private static let service = "com.milli.taxvault.local-auth"

    static func store(password: String, for email: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }

        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email
        ]

        SecItemDelete(base as CFDictionary)

        var insert = base
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }

    static func passwordMatches(_ password: String, for email: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let storedPassword = String(data: data, encoding: .utf8)
        else {
            return false
        }

        return storedPassword == password
    }
}

#Preview {
    LoginView(onSignIn: { _ in }, onCreateAccount: { _ in })
}
