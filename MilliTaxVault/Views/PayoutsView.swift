import SwiftUI

// MARK: - PayoutsView
// Dense banking-grade payout history with compact segmented filtering.
// Seed data is isolated in one place so the screen can be swapped to the payout repository/API cleanly.

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
            Text("Total \(currency(totalPayouts))")
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
                .accessibilityLabel("Show \(filter.title.lowercased()) payouts")
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color(hex: "0C252E"))
                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 0.7))
        )
    }

    @ViewBuilder
    private var payoutList: some View {
        if filteredPayouts.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(MilliColors.textTertiary)
                Text("No payouts in this view")
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .milliCard()
        } else {
            LazyVStack(spacing: 8) {
                ForEach(filteredPayouts) { payout in
                    payoutRow(payout)
                }
            }
        }
    }

    private var totalPayouts: Double {
        payoutData.reduce(0) { $0 + $1.amount }
    }

    private var filteredPayouts: [PayoutItem] {
        switch selectedFilter {
        case .all:
            return payoutData
        case .thisWeek:
            return payoutData.filter(\.isThisWeek)
        case .pending:
            return payoutData.filter { $0.status == .pending }
        }
    }

    private func payoutRow(_ payout: PayoutItem) -> some View {
        HStack(spacing: 10) {
            platformMark(payout)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(payout.platform)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)

                    if payout.status == .pending {
                        Text("PENDING")
                            .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                            .tracking(0.5)
                            .foregroundStyle(MilliColors.warning)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(MilliColors.warning.opacity(0.10)))
                    }
                }

                Text(payout.dateLabel)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Text("+\(currency(payout.amount))")
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(payout.status == .pending ? MilliColors.textPrimary : MilliColors.positive)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(payout.platform), \(payout.dateLabel), \(currency(payout.amount)), \(payout.status.accessibilityLabel)")
    }

    @ViewBuilder
    private func platformMark(_ payout: PayoutItem) -> some View {
        if let assetName = payout.assetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.13), lineWidth: 0.7))
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [payout.platformColor.opacity(0.95), payout.platformColor.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 42, height: 42)
                .overlay {
                    Text(payout.platformInitial)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .overlay(Circle().stroke(Color.white.opacity(0.13), lineWidth: 0.7))
        }
    }

    private var payoutData: [PayoutItem] {
        [
            .init(platform: "Spark Driver", platformInitial: "S", assetName: "spark-driver-icon", platformColor: Color(hex: "0879FF"), dateLabel: "Today, 9:41 AM", amount: 312.64, status: .settled, isThisWeek: true),
            .init(platform: "Uber", platformInitial: "U", assetName: "uber-icon", platformColor: .black, dateLabel: "Yesterday", amount: 186.42, status: .settled, isThisWeek: true),
            .init(platform: "DoorDash", platformInitial: "D", assetName: "doordash-icon", platformColor: Color(hex: "4B170D"), dateLabel: "Yesterday", amount: 94.16, status: .pending, isThisWeek: true),
            .init(platform: "Instacart", platformInitial: "I", assetName: "instacart-icon", platformColor: Color(hex: "064D2A"), dateLabel: "2 days ago", amount: 128.10, status: .settled, isThisWeek: true),
            .init(platform: "DoorDash", platformInitial: "D", assetName: "doordash-icon", platformColor: Color(hex: "4B170D"), dateLabel: "3 days ago", amount: 116.73, status: .settled, isThisWeek: true),
            .init(platform: "Uber", platformInitial: "U", assetName: "uber-icon", platformColor: .black, dateLabel: "4 days ago", amount: 205.58, status: .pending, isThisWeek: true),
            .init(platform: "Instacart", platformInitial: "I", assetName: "instacart-icon", platformColor: Color(hex: "064D2A"), dateLabel: "Last week", amount: 173.62, status: .settled, isThisWeek: false),
            .init(platform: "Spark Driver", platformInitial: "S", assetName: "spark-driver-icon", platformColor: Color(hex: "0879FF"), dateLabel: "Last week", amount: 181.48, status: .settled, isThisWeek: false)
        ]
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
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

enum PayoutStatus {
    case settled
    case pending

    var accessibilityLabel: String {
        switch self {
        case .settled: return "settled"
        case .pending: return "pending"
        }
    }
}

struct PayoutItem: Identifiable {
    let id = UUID()
    let platform: String
    let platformInitial: String
    let assetName: String?
    let platformColor: Color
    let dateLabel: String
    let amount: Double
    let status: PayoutStatus
    let isThisWeek: Bool
}
