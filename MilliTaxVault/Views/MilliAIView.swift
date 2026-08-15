import SwiftUI

// MARK: - MilliAIView — Screen 11: AI chat assistant
// Robot avatar | Greeting | Chat bubbles | Input field

struct MilliAIView: View {
    var onBack: () -> Void = {}
    @State private var messageText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            // Chat content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: MilliSpacing.lg) {
                    robotAvatar
                    greetingSection
                    chatBubbles
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.top, MilliSpacing.md)
                .padding(.bottom, MilliSpacing.lg)
            }

            Spacer()

            // Input field
            inputSection
        }
        .background(MilliColors.background.ignoresSafeArea())
        .padding(.bottom, 78) // Nav bar clearance
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button { onBack() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MilliColors.textSecondary)
            }
            .buttonStyle(.plain)

            Text("Milli AI")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Spacer()
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.vertical, MilliSpacing.md)
    }

    // MARK: - Robot Avatar

    private var robotAvatar: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(MilliColors.cyanGlow.opacity(0.08))
                .frame(width: 100, height: 100)

            // Robot body
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1A2E4A"), Color(hex: "0D1B2E")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 64, height: 56)
                .overlay(
                    VStack(spacing: 8) {
                        // Eyes
                        HStack(spacing: 14) {
                            Circle()
                                .fill(MilliColors.cyanGlow)
                                .frame(width: 10, height: 10)
                                .shadow(color: MilliColors.cyanGlow.opacity(0.8), radius: 4)
                            Circle()
                                .fill(MilliColors.cyanGlow)
                                .frame(width: 10, height: 10)
                                .shadow(color: MilliColors.cyanGlow.opacity(0.8), radius: 4)
                        }
                        // Mouth
                        RoundedRectangle(cornerRadius: 2)
                            .fill(MilliColors.cyanGlow.opacity(0.5))
                            .frame(width: 20, height: 4)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.3), lineWidth: 1)
                )

            // Antenna
            VStack(spacing: 0) {
                Circle()
                    .fill(MilliColors.cyanGlow)
                    .frame(width: 8, height: 8)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.6), radius: 4)
                Rectangle()
                    .fill(MilliColors.cyanGlow.opacity(0.5))
                    .frame(width: 2, height: 12)
            }
            .offset(y: -38)
        }
        .padding(.top, MilliSpacing.lg)
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(spacing: 6) {
            Text("Hi Ian! \u{1F44B}")
                .font(MilliFont.displaySmall)
                .foregroundColor(MilliColors.textPrimary)

            Text("How can I help guide your finances today?")
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Chat Bubbles

    private var chatBubbles: some View {
        VStack(spacing: MilliSpacing.md) {
            // User message
            HStack {
                Spacer()
                Text("Am I on track for tax season?")
                    .font(MilliFont.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(MilliColors.cyanGlow.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(MilliColors.cyanGlow.opacity(0.4), lineWidth: 0.5)
                            )
                    )
            }

            // AI response
            HStack(alignment: .top, spacing: 10) {
                // Mini robot icon
                ZStack {
                    Circle()
                        .fill(MilliColors.cardBackground)
                        .frame(width: 30, height: 30)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "1A2E4A"))
                        .frame(width: 18, height: 14)
                        .overlay(
                            HStack(spacing: 4) {
                                Circle().fill(MilliColors.cyanGlow).frame(width: 4, height: 4)
                                Circle().fill(MilliColors.cyanGlow).frame(width: 4, height: 4)
                            }
                        )
                }

                Text("Yes! You're on pace to save $3,421 in taxes this year. Your Tax Ready Score is 85 which is great.")
                    .font(MilliFont.bodyMedium)
                    .foregroundColor(MilliColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(MilliColors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(MilliColors.cardBorderGlow, lineWidth: 0.5)
                            )
                    )

                Spacer()
            }
        }
    }

    // MARK: - Input Field

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Ask Milli AI anything...", text: $messageText)
                .font(MilliFont.bodyMedium)
                .foregroundColor(MilliColors.textPrimary)
                .focused($isInputFocused)
                .tint(MilliColors.cyanGlow)

            Button {} label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(messageText.isEmpty ? MilliColors.textTertiary : MilliColors.cyanGlow)
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(MilliColors.border, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.bottom, MilliSpacing.sm)
    }
}
