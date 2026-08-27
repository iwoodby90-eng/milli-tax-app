import SwiftUI

// MARK: - MilliAIView
// Dedicated assistant surface using Milli's transparent vector companion.
// Until a production conversational-AI endpoint is connected, the screen uses a
// deterministic on-device routing fallback rather than pretending a remote model answered.

struct MilliAIView: View {
    var onBack: () -> Void = {}
    var navigate: ((ActiveScreen) -> Void)? = nil

    @State private var messageText = ""
    @State private var messages: [MilliAIMessage] = MilliAIMessage.seedConversation
    @State private var companionFloat: CGFloat = 1
    @State private var assistantState: MilliAIState = .front
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        intro

                        ForEach(messages) { message in
                            messageView(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 6)
                    .padding(.bottom, 18)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            composer
                .padding(.bottom, MilliSpacing.bottomNavHeight - 2)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                companionFloat = -3
            }
        }
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

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MilliColors.textTertiary)
                    .frame(width: 34, height: 34)
                    .accessibilityLabel("Private assistant session")
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
        VStack(spacing: 14) {
            // Spec section 5: full AI hero 200-240pt with soft cyan glow,
            // centered above the greeting card.
            aiPortrait(size: 220, animated: true, state: assistantState)
                .shadow(color: MilliColors.cyanGlow.opacity(0.40), radius: 18)
                .offset(y: companionFloat)

            VStack(alignment: .leading, spacing: 5) {
                Text("How can I help?")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Ask about taxes, payouts, mileage, retirement, investing, or whether a gig offer makes financial sense.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .milliCard(padding: 12)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func messageView(_ message: MilliAIMessage) -> some View {
        switch message.role {
        case .user:
            userBubble(message.text)
        case .assistant:
            aiCard(message)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 58)
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

    private func aiCard(_ message: MilliAIMessage) -> some View {
        HStack(alignment: .top, spacing: 7) {
            aiPortrait(size: 42, animated: false)

            VStack(alignment: .leading, spacing: 10) {
                Text(message.text)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle = message.actionTitle,
                   let destination = message.destination {
                    Button {
                        navigate?(destination)
                    } label: {
                        HStack(spacing: 6) {
                            Text(actionTitle)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
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
            }
            .milliCard(padding: 12)

            Spacer(minLength: 14)
        }
    }

    private func aiPortrait(size: CGFloat, animated: Bool, state: MilliAIState? = nil) -> some View {
        MilliAICharacterView(size: size, animated: animated, state: state)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask Milli AI anything...", text: $messageText, axis: .vertical)
                .lineLimit(1...3)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textPrimary)
                .focused($isInputFocused)
                .tint(MilliColors.cyanGlow)
                .submitLabel(.send)
                .onSubmit(sendMessage)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(canSend ? MilliColors.blackGlass : MilliColors.textTertiary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(canSend ? MilliColors.cyanGlow : Color.white.opacity(0.04))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 48)
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

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(.init(role: .user, text: text))
        messageText = ""
        isInputFocused = false

        // Assistant state flow: processing -> responding.
        // The visual state never asserts a financial outcome; success/alert are
        // reserved for confirmed transaction states elsewhere in the app.
        assistantState = .thinking
        let response = MilliAIFallbackEngine.response(to: text)
        withAnimation(.easeOut(duration: 0.2)) {
            messages.append(response)
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
            assistantState = .speaking
        }
        withAnimation(.easeOut(duration: 0.3).delay(2.4)) {
            assistantState = .front
        }
    }
}

private struct MilliAIMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
    let actionTitle: String?
    let destination: ActiveScreen?

    init(
        role: Role,
        text: String,
        actionTitle: String? = nil,
        destination: ActiveScreen? = nil
    ) {
        self.role = role
        self.text = text
        self.actionTitle = actionTitle
        self.destination = destination
    }

    static let seedConversation: [MilliAIMessage] = [
        MilliAIMessage(
            role: .assistant,
            text: "Your tax reserve, mileage activity, and long-term planning are available throughout Milli. Ask me where you want to start.",
            actionTitle: "Review Tax Readiness",
            destination: .taxReadyScore
        )
    ]
}

private enum MilliAIFallbackEngine {
    static func response(to text: String) -> MilliAIMessage {
        let query = text.lowercased()

        if query.contains("tax") || query.contains("owe") || query.contains("quarter") {
            return MilliAIMessage(
                role: .assistant,
                text: "I can take you directly to your current quarterly estimate and Tax Ready Score. Live conversational tax analysis will use your authenticated financial data once the production AI service is connected.",
                actionTitle: "View Quarterly Taxes",
                destination: .quarterlyTaxes
            )
        }

        if query.contains("mile") || query.contains("trip") || query.contains("drive") {
            return MilliAIMessage(
                role: .assistant,
                text: "Your Mileage screen is the source of truth for tracked business miles, route activity, and deduction estimates.",
                actionTitle: "View Mileage",
                destination: .activity
            )
        }

        if query.contains("retire") || query.contains("401") || query.contains("future") {
            return MilliAIMessage(
                role: .assistant,
                text: "Your retirement projection can model contribution percentage, target retirement age, total contributions, and projected investment growth.",
                actionTitle: "Review Retirement",
                destination: .retirement
            )
        }

        if query.contains("invest") || query.contains("market") || query.contains("portfolio") {
            return MilliAIMessage(
                role: .assistant,
                text: "The Investing view contains your portfolio surface, holdings, live market indicators, and OHLC candlestick chart.",
                actionTitle: "View Investing",
                destination: .investing
            )
        }

        if query.contains("offer") || query.contains("doordash") || query.contains("uber") || query.contains("spark") || query.contains("profitable") {
            return MilliAIMessage(
                role: .assistant,
                text: "Milli Cents™ evaluates offer amount against total miles, dead distance, return distance, fuel cost, tax impact, net profit, and profit per mile before returning GO, MAYBE, or NO.",
                actionTitle: "Analyze an Offer",
                destination: .milliCents
            )
        }

        if query.contains("vault") || query.contains("reserve") || query.contains("save") {
            return MilliAIMessage(
                role: .assistant,
                text: "Milli Tax Vault™ shows your protected tax reserve, annual target progress, and auditable allocation ledger.",
                actionTitle: "Open Tax Vault",
                destination: .taxVault
            )
        }

        return MilliAIMessage(
            role: .assistant,
            text: "The conversational AI service is not connected in this build yet, so I won't invent a financial answer. I can still route you to the relevant Milli planning and reporting tools.",
            actionTitle: "Open Reports",
            destination: .reports
        )
    }
}