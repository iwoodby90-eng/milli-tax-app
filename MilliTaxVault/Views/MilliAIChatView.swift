import SwiftUI

struct MilliAIChatView: View {
    var onBack: (() -> Void)?

    @State private var messageText = ""

    struct ChatMessage: Identifiable {
        let id = UUID()
        let isAI: Bool
        let text: String
        let buttonLabel: String?
    }

    // The transcript starts with the greeting only. Figures come from the
    // user's own connected data once an assistant response is grounded in it.
    let messages: [ChatMessage] = [
        ChatMessage(
            isAI: true,
            text: "Hi! I'm Milli AI. Connect your bank and I'll answer questions about your taxes, deductions and payouts using your real numbers.",
            buttonLabel: nil
        )
    ]

    var body: some View {
        ZStack {
            MilliAmbientBackground()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
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

                // Messages - bottom-aligned with ScrollViewReader
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            Spacer(minLength: 200)
                            ForEach(messages) { msg in
                                HStack(alignment: .top, spacing: 10) {
                                    if msg.isAI {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 20))
                                            .foregroundColor(MilliColors.cyanGlow)
                                            .frame(width: 32)
                                    }
                                    VStack(alignment: msg.isAI ? .leading : .trailing, spacing: 8) {
                                        Text(msg.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .padding(14)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(msg.isAI ? MilliColors.elevated : MilliColors.cyanGlow.opacity(0.15))
                                            )
                                        if let btn = msg.buttonLabel {
                                            Button(action: {}) {
                                                Text(btn)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(MilliColors.cyanGlow)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .overlay(Capsule().stroke(MilliColors.cyanGlow, lineWidth: 1))
                                            }
                                        }
                                    }
                                    if !msg.isAI { Spacer().frame(width: 32) }
                                }
                                .frame(maxWidth: .infinity, alignment: msg.isAI ? .leading : .trailing)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(20)
                    }
                    .onAppear {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Ask Milli AI anything...", text: $messageText)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 24).fill(MilliColors.carbon))
                    Button(action: {}) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(MilliColors.cyanGlow))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(MilliColors.carbon)
            }
        }
    }
}

#Preview {
    MilliAIChatView()
}
