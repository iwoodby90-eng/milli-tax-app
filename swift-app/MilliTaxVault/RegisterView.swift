import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showRegister: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Header
                VStack(spacing: 8) {
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

                    Text("Create Your Account")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.milliTextSecondary)
                }
                .padding(.bottom, 32)

                // Register Card
                MilliCard {
                    VStack(spacing: 18) {
                        // Name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FULL NAME")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(.milliTextSecondary)

                            TextField("", text: $name)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .textContentType(.name)
                                .padding(12)
                                .background(Color.milliBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.milliCardBorder, lineWidth: 0.5)
                                )
                        }

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
                                .textContentType(.newPassword)
                                .padding(12)
                                .background(Color.milliBackground)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.milliCardBorder, lineWidth: 0.5)
                                )

                            Text("Minimum 12 characters")
                                .font(.system(size: 11))
                                .foregroundColor(.milliTextTertiary)
                        }

                        // Error message
                        if let error = appState.errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "FF4444"))
                                .multilineTextAlignment(.center)
                        }

                        // Register button
                        Button(action: {
                            Task {
                                await appState.register(name: name, email: email, password: password)
                            }
                        }) {
                            HStack {
                                if appState.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
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
                        .disabled(!formValid || appState.isLoading)
                        .opacity(formValid ? 1.0 : 0.6)
                    }
                }
                .padding(.horizontal, 24)

                // Back to login link
                Button(action: { showRegister = false }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.milliTextSecondary)
                        Text("Sign In")
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

    private var formValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 12
    }
}
