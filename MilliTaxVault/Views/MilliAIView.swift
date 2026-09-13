import SwiftUI
import UIKit

// MARK: - MilliAIView
// Premium assistant surface. The approved Milli AI character is a visual anchor,
// while the conversation remains restrained and finance-first rather than chat-app generic.

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
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        assistantHero
                        quickActions

                        ForEach(messages) { message in
                            messageView(message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
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
        .background(
            ZStack {
                MilliColors.background.ignoresSafeArea()
                RadialGradient(
                    colors: [MilliColors.cyanGlow.opacity(0.055), Color.clear],
                    center: UnitPoint(x: 0.84, y: 0.10),
                    startRadius: 0,
                    endRadius: 260
                )
                .ignoresSafeArea()
            }
        )
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                    Text("PRIVATE")
                }
                .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                .tracking(0.65)
                .foregroundStyle(MilliColors.textTertiary)
            }

            Text("MILLI AI")
                .font(.custom("Sora-SemiBold", size: 16, relativeTo: .headline))
                .tracking(3.2)
                .foregroundStyle(MilliColors.silverBright)
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var assistantHero: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Hi, I'm Milli.")
                    .font(.custom("Sora-Bold", size: 25, relativeTo: .title2))
                    .foregroundStyle(MilliColors.textPrimary)

                Text("Your financial copilot for taxes, payouts, mileage, planning, and smarter money decisions.")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Circle()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: 5, height: 5)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.6), radius: 3)
                    Text("Ready to help")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.cyanGlow)
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MilliAICharacterView(size: 122, animated: true)
                .frame(width: 116, height: 122)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
    }

    private var quickActions: some View {
        VStack(spacing: 0) {
            ForEach(Array(quickPrompts.enumerated()), id: \.offset) { index, prompt in
                Button {
                    submitPrompt(prompt)
                } label: {
                    HStack(spacing: 10) {
                        Text(prompt)
                            .font(.custom("Inter-Medium", size: 12.5, relativeTo: .footnote))
                            .foregroundStyle(MilliColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                    .padding(.horizontal, 13)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)

                if index < quickPrompts.count - 1 {
                    Divider()
                        .overlay(Color.white.opacity(0.055))
                        .padding(.leading, 13)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0D151A"), Color(hex: "080C0F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                }
        )
    }

    @ViewBuilder
    private func messageView(_ message: MilliAIMessage) -> some View {
        switch message.role {
        case .user:
            userBubble(message.text)
        case .assistant:
            aiResponse(message)
        }
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 64)
            Text(text)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.blackGlass)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
    }

    private func aiResponse(_ message: MilliAIMessage) -> some View {
        HStack(alignment: .top, spacing: 9) {
            MilliAICharacterView(size: 44, animated: false)
                .frame(width: 44, height: 44)

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
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 13)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.white.opacity(0.025))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                    }
            )
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
                    .frame(width: 31, height: 31)
                    .background(
                        Circle()
                            .fill(canSend ? MilliColors.cyanGlow : Color.white.opacity(0.04))
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 13)
        .frame(minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "0B1115"))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
                }
        )
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 7)
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        withAnimation(.easeOut(duration: 0.2)) {
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
