import SwiftUI

// MARK: - PayoutsView
// Dense banking-grade payout history with compact segmented filtering and an
// auditable Financial Receipt™ detail for every payout.

struct PayoutsView: View {
    @State private var selectedFilter: PayoutFilter = .all
    @State private var selectedPayout: PayoutItem?

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
        .sheet(item: $selectedPayout) { payout in
            FinancialReceiptSheet(payout: payout)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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
                    Button {
                        selectedPayout = payout
                    } label: {
                        payoutRow(payout)
                    }
                    .buttonStyle(.plain)
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

            VStack(alignment: .trailing, spacing: 3) {
                Text("+\(currency(payout.amount))")
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(payout.status == .pending ? MilliColors.textPrimary : MilliColors.positive)
                Text("Financial Receipt™")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.cyanGlow)
            }
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
        .accessibilityLabel("\(payout.platform), \(payout.dateLabel), \(currency(payout.amount)), \(payout.status.accessibilityLabel). Open Financial Receipt")
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
            .init(receiptCode: "AP-2026-000025", platform: "Spark Driver", platformInitial: "S", assetName: "spark-driver-icon", platformColor: Color(hex: "0879FF"), dateLabel: "Today, 9:41 AM", amount: 312.64, status: .settled, isThisWeek: true),
            .init(receiptCode: "AP-2026-000024", platform: "Uber", platformInitial: "U", assetName: "uber-icon", platformColor: .black, dateLabel: "Yesterday", amount: 186.42, status: .settled, isThisWeek: true),
            .init(receiptCode: "AP-2026-000023", platform: "DoorDash", platformInitial: "D", assetName: "doordash-icon", platformColor: Color(hex: "4B170D"), dateLabel: "Yesterday", amount: 94.16, status: .pending, isThisWeek: true),
            .init(receiptCode: "AP-2026-000022", platform: "Instacart", platformInitial: "I", assetName: "instacart-icon", platformColor: Color(hex: "064D2A"), dateLabel: "2 days ago", amount: 128.10, status: .settled, isThisWeek: true),
            .init(receiptCode: "AP-2026-000021", platform: "DoorDash", platformInitial: "D", assetName: "doordash-icon", platformColor: Color(hex: "4B170D"), dateLabel: "3 days ago", amount: 116.73, status: .settled, isThisWeek: true),
            .init(receiptCode: "AP-2026-000020", platform: "Uber", platformInitial: "U", assetName: "uber-icon", platformColor: .black, dateLabel: "4 days ago", amount: 205.58, status: .pending, isThisWeek: true),
            .init(receiptCode: "AP-2026-000019", platform: "Instacart", platformInitial: "I", assetName: "instacart-icon", platformColor: Color(hex: "064D2A"), dateLabel: "Last week", amount: 173.62, status: .settled, isThisWeek: false),
            .init(receiptCode: "AP-2026-000018", platform: "Spark Driver", platformInitial: "S", assetName: "spark-driver-icon", platformColor: Color(hex: "0879FF"), dateLabel: "Last week", amount: 181.48, status: .settled, isThisWeek: false)
        ]
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

// MARK: - Financial Receipt™

private struct FinancialReceiptSheet: View {
    @Environment(\.dismiss) private var dismiss
    let payout: PayoutItem

    private let taxRate = 0.23
    private let retirementRate = 0.05
    private let investingRate = 0.00
    private let savingsRate = 0.03

    private var taxReserve: Double { payout.amount * taxRate }
    private var retirement: Double { payout.amount * retirementRate }
    private var investing: Double { payout.amount * investingRate }
    private var savings: Double { payout.amount * savingsRate }
    private var available: Double {
        payout.amount - taxReserve - retirement - investing - savings
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        receiptHeader
                        payoutSummary
                        allocationCard
                        verificationCard
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 14)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Financial Receipt™")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var receiptHeader: some View {
        VStack(spacing: 9) {
            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 62, height: 62)

            Text("MILLI AUTOPILOT™")
                .font(MilliFont.sectionLabel)
                .tracking(1.4)
                .foregroundStyle(MilliColors.cyanGlow)

            Text(payout.receiptCode)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var payoutSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                platformAsset

                VStack(alignment: .leading, spacing: 2) {
                    Text(payout.platform)
                        .font(MilliFont.headline)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(payout.dateLabel)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer()
            }

            Divider().overlay(Color.white.opacity(0.06))

            receiptLine("Payout received", payout.amount, color: MilliColors.textPrimary)
            receiptLine("Processing status", payout.status == .settled ? 1 : 0, textualValue: payout.status == .settled ? "Settled" : "Pending", color: payout.status == .settled ? MilliColors.positive : MilliColors.warning)
        }
        .milliCard(padding: 14)
    }

    @ViewBuilder
    private var platformAsset: some View {
        if let assetName = payout.assetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(payout.platformColor)
                .frame(width: 42, height: 42)
                .overlay {
                    Text(payout.platformInitial)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                }
        }
    }

    private var allocationCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("AUTOPILOT ALLOCATION")
                    .sectionHeaderStyle()
                Spacer()
                Text("Seed settings")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            allocationLine("Milli Tax Vault™", taxReserve, rate: taxRate, icon: "lock.shield.fill", color: MilliColors.cyanGlow)
            allocationLine("Retirement", retirement, rate: retirementRate, icon: "building.columns.fill", color: MilliColors.positive)
            allocationLine("Investing", investing, rate: investingRate, icon: "chart.line.uptrend.xyaxis", color: Color(hex: "7C8CFF"))
            allocationLine("Savings", savings, rate: savingsRate, icon: "banknote.fill", color: MilliColors.deepCyan)

            Divider().overlay(Color.white.opacity(0.07))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AVAILABLE TO SPEND")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text("After current seed allocations")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text(available.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
        }
        .milliCard(padding: 14)
    }

    private func allocationLine(_ title: String, _ amount: Double, rate: Double, icon: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.09)))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(rate.formatted(.percent.precision(.fractionLength(0))))
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Text(amount.formatted(.currency(code: "USD")))
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(amount == 0 ? MilliColors.textTertiary : MilliColors.textPrimary)
        }
    }

    private var verificationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(MilliColors.positive)
                Text("Receipt integrity")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Spacer()
                Text("LOCAL DEMO")
                    .font(MilliFont.caption)
                    .tracking(0.5)
                    .foregroundStyle(MilliColors.warning)
            }

            Text("This receipt screen is wired to the payout model and allocation math. Cryptographic signing/verification must remain disabled until the production receipt-signing service is connected; the UI does not claim a fake verified signature.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 14)
    }

    private func receiptLine(_ title: String, _ amount: Double, textualValue: String? = nil, color: Color) -> some View {
        HStack {
            Text(title)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            Spacer()
            if let textualValue {
                Text(textualValue)
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(color)
            } else {
                Text(amount.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(color)
            }
        }
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
    let receiptCode: String
    let platform: String
    let platformInitial: String
    let assetName: String?
    let platformColor: Color
    let dateLabel: String
    let amount: Double
    let status: PayoutStatus
    let isThisWeek: Bool
}
