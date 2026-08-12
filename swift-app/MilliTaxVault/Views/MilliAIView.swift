import SwiftUI

// MARK: - Milli AI (Floating Companion Sheet)
// Transparent-feel conversational AI assistant. Presented from the floating orb.

struct MilliAIView: View {
    @Environment(\.dismiss) var dismiss
    @State private var messages: [AIMessage] = [
        AIMessage(isUser: false, text: "Hey! I'm Milli, your tax-smart copilot. Ask me anything about deductions, mileage, or your vault strategy.")
    ]
    @State private var inputText = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            // Semi-transparent dark background
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                Divider().background(MilliPalette.cardBorder)

                // Messages
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { msg in
                                messageBubble(msg)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                // Input
                inputBar
            }
        }
        .onAppear { inputFocused = true }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(MilliPalette.accent.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MilliPalette.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Milli AI")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Always here to help")
                        .font(.system(size: 10))
                        .foregroundColor(MilliPalette.textSecondary)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(MilliPalette.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Message Bubble

    private func messageBubble(_ msg: AIMessage) -> some View {
        HStack {
            if msg.isUser { Spacer() }
            Text(msg.text)
                .font(.system(size: 14))
                .foregroundColor(msg.isUser ? .black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(msg.isUser ? MilliPalette.accent : MilliPalette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(msg.isUser ? Color.clear : MilliPalette.cardBorder, lineWidth: 0.5)
                )
                .id(msg.id)
            if !msg.isUser { Spacer() }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Milli...", text: $inputText)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .focused($inputFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MilliPalette.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MilliPalette.cardBorder, lineWidth: 1)
                )
                .submitLabel(.send)
                .onSubmit { sendMessage() }

            Button { sendMessage() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? MilliPalette.textSecondary : MilliPalette.accent)
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.4))
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(AIMessage(isUser: true, text: text))
        inputText = ""
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append(AIMessage(isUser: false, text: "I'll look into that for you. Give me just a moment..."))
        }
    }
}

// MARK: - AI Message Model

struct AIMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
}
