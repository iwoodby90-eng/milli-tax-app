import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false

    private var passwordsMatch: Bool { !password.isEmpty && password == confirmPassword }
    private var formValid: Bool { !name.isEmpty && !email.isEmpty && passwordsMatch }

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            RadialGradient(
                colors: [MilliPalette.accent.opacity(0.03), Color.clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 350
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 40)

                    // Header
                    headerSection
                    Spacer().frame(height: 36)

                    // Form
                    formSection
                    Spacer().frame(height: 28)

                    // Create button
                    createButton

                    // Error
                    if let error = appState.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(MilliPalette.negative)
                            .padding(.top, 12)
                            .multilineTextAlignment(.center)
                    }

                    Spacer().frame(height: 24)

                    // Back to login
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(MilliPalette.textSecondary)
                            Text("Sign In")
                                .foregroundColor(MilliPalette.accent)
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 14))
                    }
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Create Account")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            Text("Start your tax-smart journey")
                .font(.system(size: 14))
                .foregroundColor(MilliPalette.textSecondary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            inputField(label: "FULL NAME", text: $name, type: .name, keyboard: .default)
            inputField(label: "EMAIL", text: $email, type: .emailAddress, keyboard: .emailAddress)

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Text("PASSWORD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MilliPalette.textSecondary)

                HStack {
                    if showPassword {
                        TextField("", text: $password)
                    } else {
                        SecureField("", text: $password)
                    }
                    Button { showPassword.toggle() } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(MilliPalette.textSecondary)
                            .font(.system(size: 14))
                    }
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MilliPalette.card))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(MilliPalette.cardBorder, lineWidth: 1))
            }

            // Confirm
            VStack(alignment: .leading, spacing: 6) {
                Text("CONFIRM PASSWORD")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MilliPalette.textSecondary)

                SecureField("", text: $confirmPassword)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MilliPalette.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                !confirmPassword.isEmpty && !passwordsMatch
                                    ? MilliPalette.negative.opacity(0.5)
                                    : MilliPalette.cardBorder,
                                lineWidth: 1
                            )
                    )
            }
        }
    }

    private func inputField(label: String, text: Binding<String>, type: UITextContentType, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(MilliPalette.textSecondary)

            TextField("", text: text)
                .textContentType(type)
                .keyboardType(keyboard)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MilliPalette.card))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(MilliPalette.cardBorder, lineWidth: 1))
        }
    }

    private var createButton: some View {
        Button {
            Task { await appState.register(fullName: name, email: email, password: password) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MilliPalette.accent)
                    .frame(height: 52)
                    .shadow(color: MilliPalette.accent.opacity(0.35), radius: 12, y: 4)

                if appState.isWorking {
                    ProgressView().tint(.black)
                } else {
                    Text("Create Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
        }
        .disabled(appState.isWorking || !formValid)
        .opacity(!formValid ? 0.5 : 1)
    }
}
