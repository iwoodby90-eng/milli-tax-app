import SwiftUI

struct LoginView: View {
    var onSignIn: () -> Void
    var onForgotPassword: (() -> Void)? = nil
    var onCreateAccount: (() -> Void)? = nil
    var onAppleSignIn: (() -> Void)? = nil
    var onGoogleSignIn: (() -> Void)? = nil

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var authenticationMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
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
        hasValidEmailShape && password.count >= 8
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                brandHero
                    .padding(.top, 58)
                    .padding(.bottom, 34)

                VStack(spacing: 12) {
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
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focusedField, equals: .password)
                            .onSubmit(submit)

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
                }

                HStack {
                    #if DEBUG
                    Button("Use Demo Account", action: fillDemoCredentials)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                    #endif

                    Spacer()

                    if let onForgotPassword {
                        Button("Forgot password?", action: onForgotPassword)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                }
                .padding(.top, 9)

                if let authenticationMessage {
                    HStack(alignment: .top, spacing: 7) {
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
                        Text("SIGN IN")
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
                                    colors: [MilliColors.cyanGlow, Color(hex: "0CBBD8")],
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

                if onAppleSignIn != nil || onGoogleSignIn != nil {
                    alternativeSignIn
                        .padding(.top, 24)
                }

                if let onCreateAccount {
                    HStack(spacing: 5) {
                        Text("New to Milli?")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                        Button("Create Account", action: onCreateAccount)
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    .padding(.top, 24)
                }

                securityFooter
                    .padding(.top, 30)
                    .padding(.bottom, 38)
            }
            .padding(.horizontal, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(loginBackground)
        .preferredColorScheme(.dark)
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

            Text("MILLI")
                .font(.custom("Sora-Bold", size: 32, relativeTo: .largeTitle))
                .tracking(6.2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeWhite],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: MilliColors.cyanGlow.opacity(0.12), radius: 5)

            Text("Money, Made Intelligent.")
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textSecondary)

            Text("Welcome back")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .padding(.top, 7)
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
                            colors: [Color(hex: "111920"), Color(hex: "0B1015")],
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
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                Text("OR")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textTertiary)
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
            }

            if let onAppleSignIn {
                Button(action: onAppleSignIn) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
                }
                .buttonStyle(.plain)
            }

            if let onGoogleSignIn {
                Button(action: onGoogleSignIn) {
                    HStack(spacing: 8) {
                        Text("G")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(MilliColors.cyanGlow)
                        Text("Continue with Google")
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
            Text("Secure access • credentials are never displayed")
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

        #if DEBUG
        if normalizedEmail == "ian@milli.local", password == "MilliDemo2026!" {
            onSignIn()
        } else {
            authenticationMessage = "This native build currently exposes only the deterministic development account. Use Demo Account while production authentication is being connected."
        }
        #else
        authenticationMessage = "Production authentication is not connected in this build yet. Milli will not simulate a successful sign-in without a verified authentication service."
        #endif
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

#Preview {
    LoginView(onSignIn: {})
}
