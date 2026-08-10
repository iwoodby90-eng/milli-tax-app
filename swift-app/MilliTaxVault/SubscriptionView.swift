import SwiftUI

// MARK: - Subscription Tier Model

struct SubscriptionTier: Identifiable {
    let id: String
    let name: String
    let price: Double
    let features: [String]
    let highlight: String?

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

// MARK: - Subscription View

struct SubscriptionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let tiers: [SubscriptionTier] = [
        SubscriptionTier(
            id: "basic",
            name: "MILLI Basic",
            price: 19.99,
            features: [
                "Payout tracking",
                "Mileage tracking",
                "Tax savings vault",
                "Quarterly tax estimates",
            ],
            highlight: nil
        ),
        SubscriptionTier(
            id: "pro",
            name: "MILLI Pro",
            price: 29.99,
            features: [
                "Everything in Basic",
                "Milli Cents unlocked",
                "Tax forms provided",
                "Guided filing assistance",
            ],
            highlight: "Most Popular"
        ),
        SubscriptionTier(
            id: "elite",
            name: "MILLI Elite",
            price: 49.99,
            features: [
                "Everything in Pro",
                "Tax forms pre-filled automatically",
                "Auto-filed and submitted",
                "Brushed Titanium Visa Card (3% cash back)",
            ],
            highlight: nil
        ),
    ]

    private var currentTier: String {
        (appState.currentUser?.tier ?? "basic").lowercased()
    }

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                MilliPageHeader(title: "Subscription", showBack: true, onBack: { dismiss() })

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Current plan badge
                        currentPlanBadge

                        // Tier cards
                        ForEach(tiers) { tier in
                            tierCard(tier)
                        }

                        // Footer note
                        Text("All plans billed monthly. Cancel anytime.")
                            .font(.system(size: 12))
                            .foregroundColor(.milliTextTertiary)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Current Plan Badge

    private var currentPlanBadge: some View {
        let currentName = tiers.first(where: { $0.id == currentTier })?.name ?? "MILLI Basic"
        let currentPrice = tiers.first(where: { $0.id == currentTier })?.formattedPrice ?? "$19.99"

        return MilliCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT PLAN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.milliTextTertiary)
                    Text(currentName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(currentPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.milliCyan)
                    Text("/month")
                        .font(.system(size: 11))
                        .foregroundColor(.milliTextSecondary)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.milliCyan.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Tier Card

    private func tierCard(_ tier: SubscriptionTier) -> some View {
        let isCurrent = tier.id == currentTier
        let isUpgrade = tierIndex(tier.id) > tierIndex(currentTier)

        return VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let highlight = tier.highlight {
                        Text(highlight.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1)
                            .foregroundColor(.milliCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.milliCyan.opacity(0.12))
                            .cornerRadius(4)
                    }
                    Text(tier.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(tier.formattedPrice)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(isCurrent ? .milliCyan : .white)
                    Text("/month")
                        .font(.system(size: 11))
                        .foregroundColor(.milliTextSecondary)
                }
            }

            // Divider
            Rectangle()
                .fill(Color.milliCardBorder)
                .frame(height: 0.5)

            // Features
            VStack(alignment: .leading, spacing: 10) {
                ForEach(tier.features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isCurrent ? .milliCyan : .milliGreen)
                        Text(feature)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.milliTextSecondary)
                    }
                }
            }

            // CTA Button
            if isCurrent {
                HStack {
                    Spacer()
                    Text("Current Plan")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.milliCyan)
                        .padding(.vertical, 12)
                    Spacer()
                }
                .background(Color.milliCyan.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.milliCyan.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button(action: {
                    // Handle plan selection — triggers Stripe checkout or StoreKit
                    selectPlan(tier.id)
                }) {
                    HStack {
                        Spacer()
                        Text(isUpgrade ? "Upgrade" : "Select Plan")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.milliBackground)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.milliBackground)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.milliCyan, Color.milliCyan.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(Color.milliCard)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isCurrent ? Color.milliCyan : Color.milliCardBorder,
                    lineWidth: isCurrent ? 1.5 : 0.5
                )
        )
        .shadow(color: isCurrent ? Color.milliCyan.opacity(0.08) : .clear, radius: 12, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func tierIndex(_ id: String) -> Int {
        switch id {
        case "basic": return 0
        case "pro": return 1
        case "elite": return 2
        default: return 0
        }
    }

    private func selectPlan(_ tierId: String) {
        Task {
            do {
                let session = try await StripeService.shared.createCheckoutSession(
                    tier: tierId,
                    originURL: "milli://subscription"
                )
                // In production, open session.url in SFSafariViewController or ASWebAuthenticationSession
                print("Checkout URL: \(session.url)")
            } catch {
                print("Checkout error: \(error)")
            }
        }
    }
}
