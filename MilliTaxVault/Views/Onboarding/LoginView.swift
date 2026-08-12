import SwiftUI

struct LoginView: View {
    var onSignIn: () -> Void
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
                
                // Chrome emblem
                ChromeEmblemView(size: 64)
                    .padding(.bottom, 16)
                
                // Wordmark
                Text("MILLI")
                    .font(.system(size: 28, weight: .bold))
                    .tracking(6)
                    .foregroundStyle(.white)
                    .padding(.bottom, 8)
                
                // Welcome text
                Text("Welcome back.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color(hex: "8E92A0"))
                    .padding(.bottom, 32)
                
                // Email field
                TextField("", text: $email, prompt: Text("Email address").foregroundStyle(Color(hex: "8E92A0")))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "121620"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                
                // Password field
                SecureField("", text: $password, prompt: Text("Password").foregroundStyle(Color(hex: "8E92A0")))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "121620"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .textContentType(.password)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                
                // Forgot password
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Text("Forgot password?")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(hex: "00E5FF"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Sign In button
                Button(action: { onSignIn() }) {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "00E5FF"))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color(hex: "8E92A0").opacity(0.3))
                        .frame(height: 1)
                    Text("or")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Rectangle()
                        .fill(Color(hex: "8E92A0").opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Continue with Apple
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                        Text("Continue with Apple")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                
                // Continue with Google
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Text("G")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "00E5FF"))
                        Text("Continue with Google")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "1C2027"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Create Account
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Button(action: {}) {
                        Text("Create Account")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "00E5FF"))
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
}

#Preview {
    LoginView(onSignIn: {})
}
