import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private let tiers: [(id: String, name: String, price: Double, features: [String], badge: String?)] = [
        ("basic", "MILLI Basic", 19.99, [
            "Payout tracking",
            "Mileage tracking",
            "Tax savings vault",
            "Quarterly tax estimates"
        ], nil),
        ("pro", "MILLI Pro", 29.99, [
            "Everything in Basic",
            "Milli Cents unlocked",
            "Tax forms provided",
            "Guided filing assistance"
        ], nil),
        ("elite", "MILLI Elite", 49.99, [
            "Everything in Pro",
            "Tax forms pre-filled automatically",
            "Auto-filed and submitted",
            "Brushed Titanium Visa Card (3% cash back)"
        ], "MOST POPULAR")
    ]

    private var currentTier: String {
        (appState.currentUser?.tier ?? "basic").lowercased()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                ForEach(tiers, id: \.id) { tier in
                    tierCard(tier)
                }

                Text("All plans billed monthly. Cancel anytime.")
                    .font(.caption)
                    .foregroundStyle(MilliPalette.textSecondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Subscription")
    }

    private func tierCard(_ tier: (id: String, name: String, price: Double, features: [String], badge: String?)) -> some View {
        let isCurrent = tier.id == currentTier
        let isElite = tier.id == "elite"

        return DKCard {
            VStack(alignment: .leading, spacing: 14) {
                // Badge
                if let badge = tier.badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(MilliPalette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(MilliPalette.accent.opacity(0.15)))
                }

                // Name + price
                HStack(alignment: .top) {
                    Text(tier.name)
                        .font(.headline)
                        .foregroundStyle(MilliPalette.textPrimary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "$%.2f", tier.price))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(isCurrent ? MilliPalette.accent : MilliPalette.textPrimary)
                        Text("/month")
                            .font(.caption2)
                            .foregroundStyle(MilliPalette.textSecondary)
                    }
                }

                Divider().overlay(MilliPalette.cardBorder)

                // Features
                ForEach(tier.features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(isCurrent ? MilliPalette.accent : MilliPalette.positive)
                        Text(feature)
                            .font(.caption)
                            .foregroundStyle(MilliPalette.textSecondary)
                    }
                }

                // CTA
                if isCurrent {
                    Text("Current Plan")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MilliPalette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(MilliPalette.accent.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MilliPalette.accent.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    Button(action: {}) {
                        Text("Select Plan")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(MilliPalette.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(MilliPalette.accent))
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                .stroke(
                    isCurrent ? MilliPalette.accent : (isElite ? MilliPalette.accent.opacity(0.5) : Color.clear),
                    lineWidth: isCurrent ? 1.5 : 1
                )
        )
        .shadow(color: isElite ? MilliPalette.accent.opacity(0.1) : .clear, radius: 12, x: 0, y: 4)
    }
}
