import SwiftUI

// MARK: - PayoutsView
// Dense banking-grade payout history with compact segmented filtering.

struct PayoutsView: View {
    @State private var selectedFilter: PayoutFilter = .all

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                filterControl
                payoutList
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(spacing: 3) {
            Text("Payouts")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)
            Text("Total $1,398.73")
                .font(MilliFont.bodyMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(MilliCardBackground(showGlow: true))
    }

    private var filterControl: some View {
        HStack(spacing: 3) {
            ForEach(PayoutFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedFilter = filter
                    }
                } label: {
                    Text(filter.title)
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(selectedFilter == filter ? MilliColors.blackGlass : MilliColors.cyanGlow.opacity(0.84))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? MilliColors.cyanGlow : Color.clear)
                                .shadow(
                                    color: selectedFilter == filter ? MilliColors.cyanGlow.opacity(0.25) : .clear,
                                    radius: 7
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(hex: "0C252E"))
                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 0.7))
        )
    }

    private var payoutList: some View {
        LazyVStack(spacing: 8) {
            ForEach(filteredPayouts) { payout in
                payoutRow(payout)
            }
        }
    }

    private var filteredPayouts: [PayoutItem] {
        switch selectedFilter {
        case .all:
            return payoutData
        case .thisWeek:
            return Array(payoutData.prefix(6))
        case .pending:
            return Array(payoutData.suffix(2))
        }
    }

    private func payoutRow(_ payout: PayoutItem) -> some View {
        HStack(spacing: 10) {
            platformMark(payout)

            VStack(alignment: .leading, spacing: 2) {
                Text(payout.platform)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(payout.date)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Text(payout.amount)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(payout.isPending ? MilliColors.textPrimary : MilliColors.positive)
        }
        .padding(.horizontal, 12)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.7)
                }
        )
    }

    private func platformMark(_ payout: PayoutItem) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [payout.platformColor.opacity(0.95), payout.platformColor.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .overlay(Circle().stroke(Color.white.opacity(0.13), lineWidth: 0.7))

            if payout.platform == "Uber" {
                Text("Uber")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white)
            } else if payout.platform == "DoorDash" {
                Image(systemName: "arrow.right")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(Color(hex: "FF3008"))
            } else if payout.platform == "Instacart" {
                Image(systemName: "carrot.fill")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.orange)
            } else {
                Text(payout.platformInitial)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        }
    }

    private var payoutData: [PayoutItem] {
        [
            PayoutItem(platform: "Uber", platformInitial: "U", platformColor: Color.black, date: "Jan 16, 2024", amount: "+$30.00", isPending: false),
            PayoutItem(platform: "DoorDash", platformInitial: "D", platformColor: Color(hex: "4B170D"), date: "Jan 16, 2024", amount: "+$16.00", isPending: true),
            PayoutItem(platform: "DoorDash", platformInitial: "D", platformColor: Color(hex: "4B170D"), date: "Jan 16, 2024", amount: "+$16.00", isPending: false),
            PayoutItem(platform: "DoorDash", platformInitial: "D", platformColor: Color(hex: "4B170D"), date: "Jan 16, 2024", amount: "+$16.00", isPending: false),
            PayoutItem(platform: "Uber", platformInitial: "U", platformColor: Color.black, date: "Jan 16, 2024", amount: "+$14.00", isPending: true),
            PayoutItem(platform: "Instacart", platformInitial: "I", platformColor: Color(hex: "064D2A"), date: "Jan 13, 2024", amount: "+$10.00", isPending: false),
            PayoutItem(platform: "Instacart", platformInitial: "I", platformColor: Color(hex: "064D2A"), date: "Jan 13, 2024", amount: "+$12.00", isPending: false),
            PayoutItem(platform: "Uber", platformInitial: "U", platformColor: Color.black, date: "Jan 13, 2024", amount: "+$10.00", isPending: false)
        ]
    }
}

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
    let isPending: Bool
}
