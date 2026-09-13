import SwiftUI

// MARK: - MilliAIView
// Canonical premium assistant surface. Milli AI is treated as a branded
// financial copilot, not a generic chat screen. The approved companion artwork
// is the hero and the interaction surfaces remain restrained and legible.

struct MilliAIView: View {
    var onBack: () -> Void = {}
    var navigate: ((ActiveScreen) -> Void)? = nil

    @State private var messageText = ""
    @State private var messages: [MilliAIMessage] = MilliAIMessage.seedConversation
    @FocusState private var isInputFocused: Bool

    private let quickPrompts = [
        "How much will I owe in taxes?",
        "When is my next payout?",
        "How can I reduce my tax bill?",
        "Show me my financial outlook"
    ]

    var body: some View {
        ZStack {
            assistantBackground

            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        assistantHero
                        quickActions
                        conversation
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }

                composer
                    .padding(.bottom, MilliSpacing.bottomNavHeight - 4)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var assistantBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "071116"), Color(hex: "030609"), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.10), Color.clear],
                center: UnitPoint(x: 0.78, y: 0.17),
                startRadius: 4,
                endRadius: 330
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textPrimary)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.035))
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.7))
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("MILLI AI")
                    .font(.custom("Sora-Bold", size: 17, relativeTo: .headline))
                    .tracking(2.6)
                    .foregroundStyle(MilliColors.silverBright)

                Text("FINANCIAL COPILOT")
                    .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                    .tracking(1.35)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 10, weight: .semibold))
                Text("PRIVATE")
                    .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                    .tracking(0.7)
            }
            .foregroundStyle(MilliColors.textTertiary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(Capsule().fill(Color.white.opacity(0.035)))
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 5)
    }

    private var assistantHero: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0A151B"), Color(hex: "04080B"), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), MilliColors.cyanGlow.opacity(0.24), Color.white.opacity(0.035)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.13), Color.clear],
                center: UnitPoint(x: 0.76, y: 0.46),
                startRadius: 0,
                endRadius: 170
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hi, I'm Milli.")
                        .font(.custom("Sora-Bold", size: 30, relativeTo: .title))
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("Ask me about taxes, payouts, mileage, planning, and the financial decisions behind your next move.")
                        .font(.custom("Inter-Regular", size: 14.5, relativeTo: .body))
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineSpacing(2.4)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 7) {
                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .frame(width: 6, height: 6)
                            .shadow(color: MilliColors.cyanGlow.opacity(0.7), radius: 4)
                        Text("READY TO HELP")
                            .font(.custom("Inter-SemiBold", size: 9, relativeTo: .caption2))
                            .tracking(0.95)
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                MilliAICharacterView(size: 154, animated: true)
                    .frame(width: 132, height: 172)
                    .offset(x: 6, y: 4)
            }
            .padding(.leading, 18)
            .padding(.trailing, 8)
            .padding(.vertical, 18)
        }
        .frame(minHeight: 220)
        .shadow(color: MilliColors.cyanGlow.opacity(0.06), radius: 24, y: 10)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ASK MILLI")
                .font(MilliFont.sectionLabel)
                .tracking(1.1)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 0) {
                ForEach(Array(quickPrompts.enumerated()), id: \.offset) { index, prompt in
                    Button {
                        submitPrompt(prompt)
                    } label: {
                        HStack(spacing: 11) {
                            ZStack {
                                Circle()
                                    .fill(MilliColors.cyanGlow.opacity(0.075))
                                    .frame(width: 29, height: 29)
                                Image(systemName: promptIcon(for: index))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(MilliColors.cyanGlow)
                            }

                            Text(prompt)
                                .font(.custom("Inter-Medium", size: 13, relativeTo: .footnote))
                                .foregroundStyle(MilliColors.textPrimary)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 6)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                        .padding(.horizontal, 12)
                        .frame(minHeight: 48)
                    }
                    .buttonStyle(.plain)

                    if index < quickPrompts.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.055))
                            .padding(.leading, 52)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.025))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.075), lineWidth: 0.7)
                    }
            )
        }
    }

    private var conversation: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !messages.isEmpty {
                Text("CONVERSATION")
                    .font(MilliFont.sectionLabel)
                    .tracking(1.1)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            ForEach(messages) { message in
                messageView(message)
            }
        }
    }

    @ViewBuilder
    private func messageView(_ message: MilliAIMessage) -> some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 58)
                Text(message.text)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.blackGlass)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }

        case .assistant:
            HStack(alignment: .top, spacing: 10) {
                MilliAICharacterView(size: 48, animated: false)
                    .frame(width: 44, height: 50)

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
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .font(MilliFont.labelLarge)
                            .foregroundStyle(MilliColors.cyanGlow)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 13)
                .background(
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(Color.white.opacity(0.025))
                        .overlay {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(Color.white.opacity(0.065), lineWidth: 0.7)
                        }
                )
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask Milli anything...", text: $messageText, axis: .vertical)
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
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(canSend ? MilliColors.cyanGlow : Color.white.opacity(0.045)))
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(Color(hex: "0A1014"))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                }
        )
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 8)
        .background(Color.black.opacity(0.96))
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func promptIcon(for index: Int) -> String {
        switch index {
        case 0: return "percent"
        case 1: return "banknote.fill"
        case 2: return "shield.lefthalf.filled"
        default: return "chart.line.uptrend.xyaxis"
        }
    }

    private func submitPrompt(_ prompt: String) {
        messageText = prompt
        sendMessage()
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(.init(role: .user, text: text))
        messageText = ""
        isInputFocused = false

        let response = MilliAIFallbackEngine.response(to: text)
        withAnimation(.easeOut(duration: 0.20)) {
            messages.append(response)
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
                text: "The Investing view contains your portfolio surface, holdings, live market indicators, and market history.",
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
