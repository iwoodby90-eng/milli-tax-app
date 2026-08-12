import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    @State private var showPassword = false

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            // Cinematic ambient glow
            RadialGradient(
                colors: [MilliPalette.accent.opacity(0.04), Color.clear],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    // Logo mark
                    logoSection

                    Spacer().frame(height: 48)

                    // Form fields
                    formFields

                    Spacer().frame(height: 32)

                    // Sign in button
                    signInButton

                    // Error message
                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(MilliPalette.negative)
                            .padding(.top, 12)
                            .multilineTextAlignment(.center)
                    }

                    Spacer().frame(height: 24)

                    // Register link
                    registerLink
                }
                .padding(.horizontal, 28)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegisterView().environmentObject(appState)
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 12) {
            // Chrome M with glow
            ZStack {
                Circle()
                    .fill(MilliPalette.accent.opacity(0.05))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [MilliPalette.chrome1, MilliPalette.chrome3],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)

                Text("M")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliPalette.chrome1, MilliPalette.accent, MilliPalette.chrome1],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: MilliPalette.accent.opacity(0.4), radius: 6)
            }

            // Wordmark
            Text("MILLI")
                .font(.system(size: 28, weight: .bold))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(white: 0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("TAX VAULT")
                .font(.system(size: 12, weight: .medium))
                .tracking(6)
                .foregroundColor(MilliPalette.textSecondary)
        }
    }

    // MARK: - Form Fields

    private var formFields: some View {
        VStack(spacing: 14) {
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Text("EMAIL")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MilliPalette.textSecondary)

                TextField("", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MilliPalette.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MilliPalette.cardBorder, lineWidth: 1)
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("PASSWORD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MilliPalette.textSecondary)

                HStack {
                    if showPassword {
                        TextField("", text: $password)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    } else {
                        SecureField("", text: $password)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(MilliPalette.textSecondary)
                            .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MilliPalette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MilliPalette.cardBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Sign In Button

    private var signInButton: some View {
        Button {
            Task { await appState.login(email: email, password: password) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MilliPalette.accent)
                    .frame(height: 52)
                    .shadow(color: MilliPalette.accent.opacity(0.35), radius: 12, y: 4)

                if appState.isWorking {
                    ProgressView().tint(.black)
                } else {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .disabled(appState.isWorking || email.isEmpty || password.isEmpty)
        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
    }

    // MARK: - Register Link

    private var registerLink: some View {
        Button { showRegister = true } label: {
            HStack(spacing: 4) {
                Text("New to Milli?")
                    .foregroundColor(MilliPalette.textSecondary)
                Text("Create Account")
                    .foregroundColor(MilliPalette.accent)
                    .fontWeight(.semibold)
            }
            .font(.system(size: 14))
        }
    }
}
