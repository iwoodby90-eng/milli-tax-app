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
            MilliPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Wordmark
                VStack(spacing: 8) {
                    Text("MILLI")
                        .font(.system(size: 36, weight: .bold, design: .default))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.milliChrome1, .white, Color.milliChrome1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Tax Vault")
                        .font(.subheadline)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                .padding(.bottom, 40)

                // Form
                VStack(spacing: 20) {
                    milliTextField(label: "EMAIL", text: $email, isSecure: false)
                    milliTextField(label: "PASSWORD", text: $password, isSecure: true)

                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(MilliPalette.negative)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: { Task { await appState.login(email: email, password: password) } }) {
                        HStack {
                            if appState.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Text("Sign In")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: MilliPalette.radius).fill(MilliPalette.accent))
                        .foregroundColor(.white)
                    }
                    .disabled(email.isEmpty || password.isEmpty || appState.isLoading)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)

                    Button(action: {}) {
                        Text("Forgot password?")
                            .font(.caption)
                            .foregroundStyle(MilliPalette.textSecondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                // Create Account ghost button
                Button(action: { showRegister = true }) {
                    Text("Create Account")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MilliPalette.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: MilliPalette.radius)
                                .stroke(MilliPalette.accent, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    private func milliTextField(label: String, text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(MilliPalette.textSecondary)

            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MilliPalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(MilliPalette.cardBorder, lineWidth: 1)
            )
        }
    }
}
