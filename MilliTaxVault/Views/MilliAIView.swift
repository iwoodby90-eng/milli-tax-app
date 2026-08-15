import SwiftUI

// MARK: - MilliAIView
// Dedicated assistant surface using the approved Milli AI character and contextual financial actions.

struct MilliAIView: View {
    var onBack: () -> Void = {}
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    intro
                    userBubble("How much will I owe in taxes this year?")
                    aiCard(
                        "Based on your income so far, I estimate you'll owe $1,247 for Q2 taxes.",
                        action: "View Tax Estimate"
                    )
                    userBubble("How can I reduce my taxes?")
                    aiCard(
                        "You could save an estimated $420 by tracking more deductions and keeping mileage complete.",
                        action: "Show Deductions"
                    )
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }

            composer
                .padding(.bottom, MilliSpacing.bottomNavHeight - 2)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                Spacer()
                Button {} label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
            }

            Text("MILLI AI")
                .font(MilliFont.headlineSmall)
                .tracking(3.0)
                .foregroundStyle(MilliColors.silverBright)
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var intro: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("MilliAIOrb")
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .shadow(color: MilliColors.cyanGlow.opacity(0.25), radius: 7)

            VStack(alignment: .leading, spacing: 5) {
                Text("Hi Alex 👋")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("I'm Milli AI. I'm here to help you save on taxes, understand your money, and build wealth.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .milliCard(padding: 12)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.blackGlass)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyanGlow, Color(hex: "19B7D7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
    }

    private func aiCard(_ text: String, action: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image("MilliAIOrb")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 10) {
                Text(text)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {} label: {
                    Text(action)
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(MilliColors.cyanGlow)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(MilliColors.cyanGlow.opacity(0.42), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
            }
            .milliCard(padding: 12)

            Spacer(minLength: 22)
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask Milli AI anything...", text: $messageText)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textPrimary)
                .focused($isInputFocused)
                .tint(MilliColors.cyanGlow)

            Button {} label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(messageText.isEmpty ? MilliColors.textTertiary : MilliColors.blackGlass)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(messageText.isEmpty ? Color.white.opacity(0.04) : MilliColors.cyanGlow)
                    )
            }
            .buttonStyle(.plain)
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(MilliColors.border, lineWidth: 0.7)
                }
        )
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 6)
    }
}
