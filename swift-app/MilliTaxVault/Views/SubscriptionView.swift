import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: Tier = .pro

    enum Tier: String, CaseIterable {
        case free = "Free"
        case pro = "Pro"
        case elite = "Elite"
    }

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Subscription")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(MilliPalette.textSecondary)
                        }
                    }

                    // Tier cards
                    ForEach(Tier.allCases, id: \.self) { tier in
                        tierCard(tier)
                    }

                    // CTA
                    if selectedTier != .free {
                        Button {} label: {
                            Text("Upgrade to \(selectedTier.rawValue)")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(MilliPalette.accent)
                                )
                                .shadow(color: MilliPalette.accent.opacity(0.3), radius: 8, y: 4)
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(24)
            }
        }
    }

    private func tierCard(_ tier: Tier) -> some View {
        let isSelected = tier == selectedTier
        let price: String = tier == .free ? "Free" : tier == .pro ? "$4.99/mo" : "$9.99/mo"
        let features: [String] = tier == .free
            ? ["Basic mileage tracking", "Manual vault transfers"]
            : tier == .pro
            ? ["Auto-save from payouts", "Quarterly reports", "Milli AI", "Unlimited tracking"]
            : ["Everything in Pro", "Priority support", "Multi-platform sync", "Tax filing assist"]

        return Button { withAnimation(.spring(response: 0.3)) { selectedTier = tier } } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tier.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? MilliPalette.accent : .white)
                    Spacer()
                    Text(price)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? MilliPalette.accent : MilliPalette.textSecondary)
                }
                ForEach(features, id: \.self) { f in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MilliPalette.accent)
                        Text(f)
                            .font(.system(size: 13))
                            .foregroundColor(MilliPalette.textSecondary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                    .fill(MilliPalette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                    .stroke(isSelected ? MilliPalette.accent : MilliPalette.cardBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}
