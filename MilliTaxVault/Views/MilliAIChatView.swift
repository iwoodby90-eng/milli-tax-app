import SwiftUI

struct MilliAIChatView: View {
    @State private var messageText = ""

    struct ChatMessage: Identifiable {
        let id = UUID()
        let isAI: Bool
        let text: String
        let buttonLabel: String?
    }

    let messages: [ChatMessage] = [
        ChatMessage(isAI: true, text: "Hi! I'm Milli AI. I'm here to help you save on taxes and build wealth. What would you like to know?", buttonLabel: nil),
        ChatMessage(isAI: false, text: "How much will I owe in taxes this year?", buttonLabel: nil),
        ChatMessage(isAI: true, text: "Based on your income so far, I estimate you'll owe $1,247 for Q2 taxes.", buttonLabel: "View Tax Estimate"),
        ChatMessage(isAI: false, text: "How can I reduce my taxes?", buttonLabel: nil),
        ChatMessage(isAI: true, text: "Great question. You could save an estimated $420 by tracking more deductions.", buttonLabel: "Show Deductions"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "0A0A0C").ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("MILLI AI")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .tracking(2)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(messages) { msg in
                            HStack(alignment: .top, spacing: 10) {
                                if msg.isAI {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "00E5FF"))
                                        .frame(width: 32)
                                }
                                VStack(alignment: msg.isAI ? .leading : .trailing, spacing: 8) {
                                    Text(msg.text)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(14)
                                        .background(
                                            msg.isAI ? Color(hex: "1A1C20") : Color(hex: "00E5FF").opacity(0.15),
                                            in: RoundedRectangle(cornerRadius: 16)
                                        )
                                    if let btn = msg.buttonLabel {
                                        Button(action: {}) {
                                            Text(btn)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(Color(hex: "00E5FF"))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .overlay(Capsule().stroke(Color(hex: "00E5FF"), lineWidth: 1))
                                        }
                                    }
                                }
                                if !msg.isAI { Spacer().frame(width: 32) }
                            }
                            .frame(maxWidth: .infinity, alignment: msg.isAI ? .leading : .trailing)
                        }
                    }
                    .padding(20)
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Ask Milli AI anything...", text: $messageText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: "111214"), in: RoundedRectangle(cornerRadius: 24))
                    Button(action: {}) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "00E5FF"), in: Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(hex: "0F1012"))
            }
        }
    }
}

#Preview {
    MilliAIChatView()
}
