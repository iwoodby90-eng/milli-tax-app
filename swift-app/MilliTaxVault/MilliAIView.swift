import SwiftUI

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let actionButton: String?

    init(isUser: Bool, text: String, actionButton: String? = nil) {
        self.isUser = isUser
        self.text = text
        self.actionButton = actionButton
    }
}

// MARK: - MilliAIView

struct MilliAIView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var inputText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: "Hi there \u{1f44b} I'm Milli AI. I'm here to help you save on taxes and build wealth. What would you like to know?"
        ),
        ChatMessage(
            isUser: true,
            text: "How much will I owe in taxes this year?"
        ),
        ChatMessage(
            isUser: false,
            text: "Based on your income so far, I estimate you'll owe $1,247 for Q2 taxes.",
            actionButton: "View Tax Estimate"
        ),
        ChatMessage(
            isUser: true,
            text: "How can I reduce my taxes?"
        ),
        ChatMessage(
            isUser: false,
            text: "Great question. You could save an estimated $420 by tracking more deductions.",
            actionButton: "Show Deductions"
        ),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatScrollView
                inputBar
            }
            .background(Color.milliBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("MILLI AI")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .kerning(1.5)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - Chat Scroll View

    private var chatScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        if message.isUser {
                            userBubble(message)
                        } else {
                            aiBubble(message)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - AI Bubble

    private func aiBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.milliAccent.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text("M")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.milliAccent)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.milliCard)
                    .cornerRadius(16)

                if let actionButton = message.actionButton {
                    Button(action: {}) {
                        Text(actionButton)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.milliAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .overlay(
                                Capsule()
                                    .stroke(Color.milliAccent, lineWidth: 1)
                            )
                    }
                }
            }

            Spacer(minLength: 40)
        }
        .id(message.id)
    }

    // MARK: - User Bubble

    private func userBubble(_ message: ChatMessage) -> some View {
        HStack {
            Spacer(minLength: 60)

            Text(message.text)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(12)
                .background(Color.milliAccent)
                .cornerRadius(16)
        }
        .id(message.id)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Milli AI anything...", text: $inputText)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.milliCard)
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            Button(action: { sendMessage() }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.milliAccent)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.milliBackground)
    }

    // MARK: - Send Message

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newMessage = ChatMessage(isUser: true, text: inputText)
        messages.append(newMessage)
        inputText = ""
    }
}

#Preview {
    MilliAIView()
        .preferredColorScheme(.dark)
}
