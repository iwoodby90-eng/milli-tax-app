import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false

    var body: some View {
        if showRegister {
            RegisterView(showRegister: $showRegister)
                .environmentObject(appState)
        } else {
            loginContent
        }
    }

    private var loginContent: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / Wordmark
                VStack(spacing: 8) {
                    Text("M")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.milliCyan, Color.milliCyan.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("MILLI")
                        .font(.system(size: 22, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.milliChrome1, Color.white, Color.milliChrome1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Tax Vault")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.milliTextSecondary)
                }
                .padding(.bottom, 40)

                // Login Card
                MilliCard {
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.milliTextSecondary)

                            TextField("", text: $email)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding(12)
                                .background(Color.milliBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.milliCardBorder, lineWidth: 0.5)
                                )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("PASSWORD")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.milliTextSecondary)

                            SecureField("", text: $password)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .textContentType(.password)
                                .padding(12)
                                .background(Color.milliBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.milliCardBorder, lineWidth: 0.5)
                                )
                        }

                        // Error message
                        if let error = appState.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "FF4444"))
                                .multilineTextAlignment(.center)
                        }

                        // Sign In button
                        Button(action: {
                            Task { await appState.login(email: email, password: password) }
                        }) {
                            HStack {
                                if appState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: [Color.milliCyan, Color.milliCyan.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(email.isEmpty || password.isEmpty || appState.isLoading)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal, 24)

                // Register link
                Button(action: { showRegister = true }) {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.milliTextSecondary)
                        Text("Create one")
                            .foregroundColor(.milliCyan)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 14))
                }
                .padding(.top, 24)

                Spacer()
            }
        }
    }
}
