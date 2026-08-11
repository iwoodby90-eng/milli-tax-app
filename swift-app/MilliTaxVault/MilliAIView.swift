import SwiftUI

struct MilliAIView: View {
    @State private var messageText = ""

    private let messages: [(role: String, text: String, button: String?)] = [
        ("bot", "Hi, I'm Milli AI. I'm here to help you save on taxes and build wealth. What would you like to know?", nil),
        ("user", "How much will I owe in taxes this year?", nil),
        ("bot", "Based on your income so far, I estimate you'll owe $1,247 for Q2 taxes.", "View Tax Estimate"),
        ("user", "How can I reduce my taxes?", nil),
        ("bot", "Great question. You could save an estimated $420 by tracking more deductions.", "Show Deductions")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(0..<messages.count, id: \.self) { index in
                        let msg = messages[index]
                        if msg.role == "bot" {
                            botBubble(text: msg.text, button: msg.button)
                        } else {
                            userBubble(text: msg.text)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            // Input bar
            inputBar
        }
        .background(MilliPalette.background.ignoresSafeArea())
    }

    // MARK: - Bot Bubble

    private func botBubble(text: String, button: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(MilliPalette.accent.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text("M")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(MilliPalette.accent)
            }

            VStack(alignment: .leading, spacing: 8) {
                DKCard(padding: 12) {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundStyle(MilliPalette.textPrimary)
                }

                if let btn = button {
                    Button(action: {}) {
                        Text(btn)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MilliPalette.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(MilliPalette.accent.opacity(0.12)))
                    }
                }
            }

            Spacer(minLength: 40)
        }
    }

    // MARK: - User Bubble

    private func userBubble(text: String) -> some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(MilliPalette.accent)
                )
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Milli AI anything...", text: $messageText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(MilliPalette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(MilliPalette.cardBorder, lineWidth: 1)
                )

            Button(action: {}) {
                Circle()
                    .fill(MilliPalette.accent)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "arrow.up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(MilliPalette.card)
    }
}
