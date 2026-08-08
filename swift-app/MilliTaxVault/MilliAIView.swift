import SwiftUI

struct MilliAIView: View {
    @State private var messageText = ""

    private let messages: [(role: String, text: String, button: String?)] = [
        ("bot", "Hi Alex, I'm Milli AI. I'm here to help you save on taxes and build wealth. What would you like to know?", nil),
        ("user", "How much will I owe in taxes this year?", nil),
        ("bot", "Based on your income so far, I estimate you'll owe $1,247 for Q2 taxes.", "View Tax Estimate"),
        ("user", "How can I reduce my taxes?", nil),
        ("bot", "Great question. You could save an estimated $420 by tracking more deductions.", "Show Deductions")
    ]

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("MILLI AI")
                        .font(.system(size: 17, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

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
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }

                // Input bar
                inputBar
            }
        }
    }

    // MARK: - Bot Bubble

    private func botBubble(text: String, button: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Robot icon
            Circle()
                .fill(Color.milliCyan.opacity(0.12))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "cpu")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.milliCyan)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.milliCard)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.milliCardBorder, lineWidth: 0.5)
                    )

                if let btn = button {
                    Button(action: {}) {
                        Text(btn)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.milliCyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.milliCyan.opacity(0.12))
                            .cornerRadius(8)
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
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white)
                .padding(12)
                .background(
                    LinearGradient(
                        colors: [Color.milliCyan, Color(hex: "0088CC")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
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
                .background(Color.milliCard)
                .cornerRadius(22)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.milliCardBorder, lineWidth: 0.5)
                )

            Button(action: {}) {
                Circle()
                    .fill(Color.milliCyan)
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
        .background(Color.milliBackground)
    }
}
