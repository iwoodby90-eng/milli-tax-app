import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showRegister: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Header
                VStack(spacing: 8) {
                    Text("MILLI")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(6)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.milliChrome1, .white, Color.milliChrome1],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Create Your Account")
                        .font(.subheadline)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                .padding(.bottom, 32)

                // Form
                VStack(spacing: 16) {
                    milliField(label: "NAME", text: $name, isSecure: false)
                    milliField(label: "EMAIL", text: $email, isSecure: false)
                    milliField(label: "PASSWORD", text: $password, isSecure: true)
                    milliField(label: "CONFIRM PASSWORD", text: $confirmPassword, isSecure: true)

                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(MilliPalette.negative)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        Task { await appState.register(fullName: name, email: email, password: password) }
                    }) {
                        HStack {
                            if appState.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Text("Create Account")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: MilliPalette.radius).fill(MilliPalette.accent))
                        .foregroundColor(.white)
                    }
                    .disabled(!formValid || appState.isLoading)
                    .opacity(formValid ? 1.0 : 0.6)
                }
                .padding(.horizontal, 24)

                // Sign In link
                Button(action: { showRegister = false }) {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(MilliPalette.textSecondary)
                        Text("Sign In")
                            .foregroundStyle(MilliPalette.accent)
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 24)

                Spacer()
            }
        }
    }

    private var formValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 12 && password == confirmPassword
    }

    private func milliField(label: String, text: Binding<String>, isSecure: Bool) -> some View {
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
