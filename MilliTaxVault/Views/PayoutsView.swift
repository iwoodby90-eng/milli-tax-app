import SwiftUI

// MARK: - PayoutsView — Screen 2: Payout history list
// Header: "Payouts" + total | Segmented tabs | Payout list

struct PayoutsView: View {
    @State private var selectedFilter: PayoutFilter = .all

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                filterTabs
                payoutsList
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            Text("Payouts")
                .font(MilliFont.screenTitle)
                .foregroundColor(MilliColors.textPrimary)

            Text("Total $1,398.73")
                .font(MilliFont.numericMedium)
                .foregroundColor(MilliColors.cyanGlow)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        HStack(spacing: MilliSpacing.sm) {
            ForEach(PayoutFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(MilliFont.labelLarge)
                        .foregroundColor(selectedFilter == filter ? MilliColors.blackGlass : MilliColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? MilliColors.cyanGlow : MilliColors.cardBackground)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedFilter == filter ? Color.clear : MilliColors.border, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Payouts List

    private var payoutsList: some View {
        VStack(spacing: MilliSpacing.sm) {
            ForEach(payoutData) { payout in
                payoutRow(payout)
            }
        }
    }

    private func payoutRow(_ payout: PayoutItem) -> some View {
        HStack(spacing: MilliSpacing.md) {
            // Platform icon
            Circle()
                .fill(payout.platformColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(payout.platformInitial)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )

            // Platform + date
            VStack(alignment: .leading, spacing: 2) {
                Text(payout.platform)
                    .font(MilliFont.headlineSmall)
                    .foregroundColor(MilliColors.textPrimary)
                Text(payout.date)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textSecondary)
            }

            Spacer()

            // Amount
            Text(payout.amount)
                .font(MilliFont.numericSmall)
                .foregroundColor(MilliColors.positive)
        }
        .padding(MilliSpacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusMd, style: .continuous)
                        .stroke(MilliColors.cardBorderGlow, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Data

    private var payoutData: [PayoutItem] {
        [
            PayoutItem(platform: "Uber", platformInitial: "U", platformColor: Color(hex: "000000"), date: "Jan 16, 2024", amount: "+$30.00"),
            PayoutItem(platform: "DoorDash", platformInitial: "D", platformColor: Color(hex: "FF3008"), date: "Jan 16, 2024", amount: "+$18.00"),
            PayoutItem(platform: "DoorDash", platformInitial: "D", platformColor: Color(hex: "FF3008"), date: "Jan 16, 2024", amount: "+$16.00"),
            PayoutItem(platform: "DoorDash", platformInitial: "D", platformColor: Color(hex: "FF3008"), date: "Jan 16, 2024", amount: "+$16.00"),
            PayoutItem(platform: "Instacart", platformInitial: "I", platformColor: Color(hex: "43B02A"), date: "Jan 15, 2024", amount: "+$14.00"),
            PayoutItem(platform: "Instacart", platformInitial: "I", platformColor: Color(hex: "43B02A"), date: "Jan 15, 2024", amount: "+$12.00"),
            PayoutItem(platform: "Uber", platformInitial: "U", platformColor: Color(hex: "000000"), date: "Jan 13, 2024", amount: "+$10.00"),
            PayoutItem(platform: "Uber", platformInitial: "U", platformColor: Color(hex: "000000"), date: "Jan 12, 2024", amount: "+$10.00"),
        ]
    }
}

// MARK: - Supporting Types

enum PayoutFilter: CaseIterable {
    case all, thisWeek, pending

    var title: String {
        switch self {
        case .all: return "All"
        case .thisWeek: return "This week"
        case .pending: return "Pending"
        }
    }
}

struct PayoutItem: Identifiable {
    let id = UUID()
    let platform: String
    let platformInitial: String
    let platformColor: Color
    let date: String
    let amount: String
}
