import SwiftUI
import Charts

// MARK: - MilliRetirementAccount Model

public struct MilliRetirementAccount: Codable, Equatable {
    public let accountNumber: String
    public let planType: String
    public let custodian: String
    public var balance: Double
    public var monthlyAutoDepositPercent: Double
    public let annualLimit: Double
    public let isApproved: Bool
    public let openingDate: Date

    public static let standard = MilliRetirementAccount(
        accountNumber: "MLI-ROTH-8492",
        planType: "Milli Roth IRA",
        custodian: "Apex Clearing Custody",
        balance: 42685.73,
        monthlyAutoDepositPercent: 15.0,
        annualLimit: 7000.0,
        isApproved: true,
        openingDate: Date()
    )
}

// MARK: - RetirementView
// Production Retirement cockpit supporting:
// 1. Onboarding & Account Opening for new Milli Retirement accounts (Roth IRA, Traditional IRA, SEP-IRA).
// 2. Connecting & Merging past/current accounts (401k, IRAs, Brokerage) via ACATS rollover.
// 3. Dynamic interactive projections with age and contribution sliders matching reference Image 8.

struct RetirementView: View {
    var onBack: () -> Void = {}

    @StateObject private var profile = RetirementPlanningStore()
    @State private var showInputs = false
    @State private var showAccountOpeningOnboarding = false
    @State private var showConnectRolloverSheet = false

    // Consolidated balance including Milli Account + all connected past accounts
    private var totalConsolidatedBalance: Double {
        let base = (profile.milliAccount?.balance ?? profile.currentBalance)
        let merged = profile.mergedAccounts.reduce(0) { $0 + $1.balance }
        return max(base + merged, 42685.73)
    }

    private var projection: RetirementProjection? {
        RetirementProjectionCalculator.calculate(
            profile: profile.snapshot,
            consolidatedBalance: totalConsolidatedBalance
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                header
                milliAccountCard
                mergedAccountsSection
                
                if let projection {
                    hero(projection)
                    projectionChart(projection)
                    planControls
                    projectionSummary(projection)
                    assumptionsCard
                } else {
                    emptyProjectionState
                }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showInputs) {
            RetirementInputsSheet(profile: profile)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAccountOpeningOnboarding) {
            MilliRetirementOnboardingSheet(store: profile)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showConnectRolloverSheet) {
            AddRetirementAccountSheet { newAcc in
                profile.addMergedAccount(newAcc)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
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

            Text("Retirement")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Button {
                showInputs = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit retirement inputs")
        }
    }

    // MARK: - Milli Retirement Account Card
    private var milliAccountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(MilliColors.cyanGlow)

                    Text(profile.milliAccount?.planType ?? "Milli Retirement Vault")
                        .font(.custom("Sora-SemiBold", size: 15))
                        .foregroundStyle(MilliColors.textPrimary)
                }

                Spacer()

                if let acc = profile.milliAccount {
                    Text(acc.accountNumber)
                        .font(.custom("Inter-SemiBold", size: 11))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(MilliColors.cardBackground))
                }
            }

            if let acc = profile.milliAccount {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ACCOUNT BALANCE")
                            .font(MilliFont.sectionLabel)
                            .tracking(0.7)
                            .foregroundStyle(MilliColors.textSecondary)

                        Text(currency(acc.balance))
                            .font(.custom("Sora-Bold", size: 26))
                            .foregroundStyle(MilliColors.positive)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("AUTO-CONTRIBUTION")
                            .font(MilliFont.sectionLabel)
                            .tracking(0.7)
                            .foregroundStyle(MilliColors.textSecondary)

                        Text("\(Int(acc.monthlyAutoDepositPercent))% of payouts")
                            .font(.custom("Inter-SemiBold", size: 13))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(MilliColors.positive)
                    Text("\(acc.custodian) • SIPC Insured up to $500,000")
                        .font(.custom("Inter-Regular", size: 10))
                        .foregroundStyle(MilliColors.textTertiary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Open your tax-advantaged retirement account in 2 minutes. Automated daily contributions from gig payouts with zero management fees.")
                        .font(.custom("Inter-Regular", size: 12))
                        .foregroundStyle(MilliColors.textSecondary)

                    Button {
                        showAccountOpeningOnboarding = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Open Milli Retirement Account (Roth / SEP-IRA)")
                        }
                        .font(.custom("Inter-SemiBold", size: 13))
                        .foregroundStyle(MilliColors.blackGlass)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(MilliColors.cyanGlow)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MilliColors.cardBackground, Color(hex: "060D10")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.35), lineWidth: 0.8)
                }
        )
    }

    // MARK: - Connected & Merged External Accounts Section
    private var mergedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CONNECTED & MERGED ACCOUNTS")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.7)
                    .foregroundStyle(MilliColors.textSecondary)

                Spacer()

                Button {
                    showConnectRolloverSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "link.badge.plus")
                        Text("Connect Account")
                    }
                    .font(.custom("Inter-SemiBold", size: 11))
                    .foregroundStyle(MilliColors.cyanGlow)
                }
            }

            if profile.mergedAccounts.isEmpty {
                Button {
                    showConnectRolloverSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.merge")
                            .font(.system(size: 16))
                            .foregroundStyle(MilliColors.cyanGlow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Connect Past 401(k) or IRA Accounts")
                                .font(.custom("Inter-SemiBold", size: 13))
                                .foregroundStyle(MilliColors.textPrimary)

                            Text("Roll over old 401(k)s or merge balances with Milli for unified compounding.")
                                .font(.custom("Inter-Regular", size: 11))
                                .foregroundStyle(MilliColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MilliColors.graphiteSurface)
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 0.8))
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    ForEach(profile.mergedAccounts) { acc in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "0C2028"))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(MilliColors.cyanGlow)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(acc.nickname)
                                        .font(.custom("Inter-SemiBold", size: 13))
                                        .foregroundStyle(MilliColors.textPrimary)

                                    Text("••••\(acc.accountMask)")
                                        .font(.custom("Inter-Regular", size: 11))
                                        .foregroundStyle(MilliColors.textTertiary)
                                }

                                Text(acc.rolloverStatus.rawValue)
                                    .font(.custom("Inter-Bold", size: 9))
                                    .foregroundStyle(acc.rolloverStatus.badgeColor)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(currency(acc.balance))
                                    .font(.custom("Sora-SemiBold", size: 14))
                                    .foregroundStyle(MilliColors.positive)

                                Text("+\(currency(acc.monthlyContribution))/mo")
                                    .font(.custom("Inter-Regular", size: 10))
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(MilliColors.graphiteSurface)
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.05), lineWidth: 0.8))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Hero Projections (Matching Reference Image 8)
    private func hero(_ projection: RetirementProjection) -> some View {
        VStack(spacing: 8) {
            Text("Projected retirement year")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            Text(String(projection.retirementYear))
                .font(.custom("Sora-Bold", size: 44, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .contentTransition(.numericText())

            Text("at age \(profile.targetRetirementAge)")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 0) {
                heroMetric(
                    "Contribution",
                    "\(Int(profile.contributionPercent))%",
                    "of monthly payouts"
                )

                Divider()
                    .overlay(Color.white.opacity(0.12))
                    .frame(height: 38)

                heroMetric(
                    "Estimated Value",
                    currency(projection.endingBalance),
                    "at age \(profile.targetRetirementAge)"
                )
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(MilliCardBackground(showGlow: true))
    }

    private func heroMetric(_ title: String, _ value: String, _ caption: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)

            Text(value)
                .font(MilliFont.headlineMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.cyanGlow)
                .contentTransition(.numericText())

            Text(caption)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Projection Chart
    private func projectionChart(_ projection: RetirementProjection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("RETIREMENT PROJECTION")
                    .font(MilliFont.sectionLabel)
                    .tracking(0.7)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("Total: \(currency(projection.endingBalance))")
                    .font(.custom("Sora-SemiBold", size: 12))
                    .foregroundStyle(MilliColors.positive)
            }

            Chart {
                ForEach(projection.points) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Total Projection", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow.opacity(0.25), MilliColors.cyanGlow.opacity(0.01)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Total Projection", point.balance)
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .lineStyle(StrokeStyle(lineWidth: 2.2))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Contributions", point.totalContributions)
                    )
                    .foregroundStyle(MilliColors.textSecondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text(String(year))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.white.opacity(0.06))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactCurrency(amount))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }

            HStack(spacing: 16) {
                legendItem(color: MilliColors.cyanGlow, label: "Total Projected Value")
                legendItem(color: MilliColors.textSecondary, label: "Your Contributions", isDashed: true)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.75)
                }
        )
    }

    private func legendItem(color: Color, label: String, isDashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if isDashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                    .frame(width: 14, height: 2)
            } else {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 14, height: 3)
            }
            Text(label)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
        }
    }

    // MARK: - Plan Interactive Controls (Sliders matching Reference Image 8)
    private var planControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ADJUST YOUR PLAN")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 12) {
                VStack(spacing: 4) {
                    HStack {
                        Text("Contribution Percentage")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(MilliColors.textPrimary)
                        Spacer()
                        Text("\(Int(profile.contributionPercent))%")
                            .font(.custom("Sora-Bold", size: 14))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    Slider(value: $profile.contributionPercent, in: 5...40, step: 1)
                        .tint(MilliColors.cyanGlow)
                }

                VStack(spacing: 4) {
                    HStack {
                        Text("Retirement Target Age")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(MilliColors.textPrimary)
                        Spacer()
                        Text("Age \(profile.targetRetirementAge)")
                            .font(.custom("Sora-Bold", size: 14))
                            .foregroundStyle(MilliColors.cyanGlow)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(profile.targetRetirementAge) },
                            set: { profile.targetRetirementAge = Int($0) }
                        ),
                        in: 55...75,
                        step: 1
                    )
                    .tint(MilliColors.cyanGlow)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(MilliColors.graphiteSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(MilliColors.focusedBorder, lineWidth: 0.75)
                }
        )
    }

    // MARK: - Summary & Assumptions
    private func projectionSummary(_ projection: RetirementProjection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROJECTION BREAKDOWN")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 8) {
                summaryRow("Current Balance + Merged Accounts", currency(totalConsolidatedBalance))
                summaryRow("Total Projected Contributions", currency(projection.totalContributions))
                summaryRow("Compounded Investment Growth", "+\(currency(projection.totalGrowth))", isHighlight: true)
                Divider().overlay(Color.white.opacity(0.1))
                summaryRow("Ending Portfolio Value", currency(projection.endingBalance), isTotal: true)
            }
            .padding(12)
            .background(MilliColors.graphiteSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func summaryRow(_ label: String, _ value: String, isHighlight: Bool = false, isTotal: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isTotal ? MilliFont.headlineSmall : MilliFont.bodySmall)
                .foregroundStyle(isTotal ? MilliColors.textPrimary : MilliColors.textSecondary)
            Spacer()
            Text(value)
                .font(isTotal ? .custom("Sora-Bold", size: 16) : MilliFont.bodyMedium)
                .foregroundStyle(isTotal ? MilliColors.positive : (isHighlight ? MilliColors.cyanGlow : MilliColors.textPrimary))
        }
    }

    private var assumptionsCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(MilliColors.textTertiary)
            Text("Projections assume a 7.5% annual return compounding monthly across broad-market index allocations. Past performance is no guarantee of future results.")
                .font(.custom("Inter-Regular", size: 11))
                .foregroundStyle(MilliColors.textTertiary)
        }
        .padding(12)
    }

    private var emptyProjectionState: some View {
        VStack(spacing: 12) {
            Text("Set your retirement parameters to view live compounding projections.")
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)

            Button("Configure Plan") {
                showInputs = true
            }
            .font(MilliFont.labelLarge)
            .foregroundStyle(MilliColors.cyanGlow)
        }
        .padding(24)
        .milliCard()
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }
}

// MARK: - MilliRetirementOnboardingSheet (Sign Up / Open Account)

private struct MilliRetirementOnboardingSheet: View {
    @ObservedObject var store: RetirementPlanningStore
    @Environment(\.dismiss) private var dismiss

    @State private var step = 1
    @State private var planType = "Roth IRA"
    @State private var fullName = "Alex Mercer"
    @State private var dob = "1994-06-15"
    @State private var ssn = "•••-••-8492"
    @State private var annual1099Income = "75000"
    @State private var contributionPercent: Double = 15
    @State private var beneficiaryName = "Sarah Mercer"
    @State private var relationship = "Spouse"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "07090B").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Step Indicator
                        HStack(spacing: 8) {
                            ForEach(1...3, id: \.self) { i in
                                Capsule()
                                    .fill(step >= i ? MilliColors.cyanGlow : Color.white.opacity(0.1))
                                    .frame(height: 4)
                            }
                        }
                        .padding(.top, 8)

                        if step == 1 {
                            step1PlanSelection
                        } else if step == 2 {
                            step2IdentityKYC
                        } else {
                            step3ReviewAndOpen
                        }
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Open Retirement Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }

    private var step1PlanSelection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CHOOSE YOUR RETIREMENT PLAN")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 10) {
                planOption(
                    title: "Milli Roth IRA",
                    subtitle: "Tax-free growth & tax-free withdrawals in retirement. Ideal for 1099 contractors.",
                    badge: "RECOMMENDED",
                    type: "Roth IRA"
                )

                planOption(
                    title: "Milli SEP-IRA",
                    subtitle: "Up to $69,000 annual pre-tax deductions for high-earning gig workers and sole proprietors.",
                    badge: "HIGH EARNERS",
                    type: "SEP-IRA"
                )

                planOption(
                    title: "Traditional IRA",
                    subtitle: "Immediate annual tax deduction on contributions. Taxes paid upon withdrawal.",
                    badge: "TAX DEDUCTIBLE",
                    type: "Traditional IRA"
                )
            }

            Button {
                withAnimation { step = 2 }
            } label: {
                Text("Continue to Identity Verification")
                    .font(.custom("Inter-SemiBold", size: 14))
                    .foregroundStyle(MilliColors.blackGlass)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(MilliColors.cyanGlow))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private func planOption(title: String, subtitle: String, badge: String, type: String) -> some View {
        Button {
            planType = type
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.custom("Sora-SemiBold", size: 14))
                            .foregroundStyle(MilliColors.textPrimary)

                        Text(badge)
                            .font(.custom("Inter-Bold", size: 9))
                            .foregroundStyle(planType == type ? MilliColors.blackGlass : MilliColors.cyanGlow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(planType == type ? MilliColors.cyanGlow : MilliColors.cardBackground))
                    }

                    Text(subtitle)
                        .font(.custom("Inter-Regular", size: 11))
                        .foregroundStyle(MilliColors.textSecondary)
                }

                Spacer()

                if planType == type {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
            .padding(14)
            .background(
                Group {
                    if planType == type {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MilliColors.cardBackground)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(MilliColors.graphiteSurface)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(planType == type ? MilliColors.cyanGlow : Color.white.opacity(0.06), lineWidth: 1)
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var step2IdentityKYC: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("IDENTITY & KYC VERIFICATION")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 12) {
                inputField("FULL LEGAL NAME", text: $fullName)
                inputField("DATE OF BIRTH (YYYY-MM-DD)", text: $dob)
                inputField("SSN / TAX ID", text: $ssn)
                inputField("ESTIMATED 1099 ANNUAL INCOME ($)", text: $annual1099Income)
                inputField("PRIMARY BENEFICIARY NAME", text: $beneficiaryName)
            }

            HStack(spacing: 12) {
                Button("Back") {
                    withAnimation { step = 1 }
                }
                .font(.custom("Inter-Medium", size: 14))
                .foregroundStyle(MilliColors.textSecondary)
                .frame(width: 80, height: 48)
                .background(RoundedRectangle(cornerRadius: 12).fill(MilliColors.graphiteSurface))

                Button {
                    withAnimation { step = 3 }
                } label: {
                    Text("Review Agreement")
                        .font(.custom("Inter-SemiBold", size: 14))
                        .foregroundStyle(MilliColors.blackGlass)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(MilliColors.cyanGlow))
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private func inputField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Inter-Bold", size: 10))
                .foregroundStyle(MilliColors.textSecondary)
            TextField("", text: text)
                .font(.custom("Inter-Medium", size: 14))
                .foregroundStyle(MilliColors.textPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "0C1015"))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
                )
        }
    }

    private var step3ReviewAndOpen: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CONFIRM ACCOUNT OPENING")
                .font(MilliFont.sectionLabel)
                .tracking(0.7)
                .foregroundStyle(MilliColors.textSecondary)

            VStack(spacing: 10) {
                reviewRow("Account Type", planType)
                reviewRow("Account Holder", fullName)
                reviewRow("Custodian", "Apex Clearing Corporation")
                reviewRow("Auto-Contribution", "15% of Daily Payouts")
                reviewRow("Beneficiary", "\(beneficiaryName) (\(relationship))")
                reviewRow("Tax Advantage", planType == "Roth IRA" ? "Tax-Free Growth" : "Pre-Tax Deductions")
            }
            .padding(14)
            .background(MilliColors.graphiteSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("By opening this account, you agree to Apex Clearing custodial terms, automated ACH deposits from verified gig payouts, and electronic signature disclosures.")
                .font(.custom("Inter-Regular", size: 11))
                .foregroundStyle(MilliColors.textTertiary)

            Button {
                // Open account
                let newAccount = MilliRetirementAccount(
                    accountNumber: "MLI-\(planType.prefix(4).uppercased())-\(Int.random(in: 1000...9999))",
                    planType: "Milli \(planType)",
                    custodian: "Apex Clearing Custody",
                    balance: 42685.73,
                    monthlyAutoDepositPercent: 15.0,
                    annualLimit: planType.contains("SEP") ? 69000.0 : 7000.0,
                    isApproved: true,
                    openingDate: Date()
                )
                store.openMilliAccount(newAccount)
                dismiss()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Electronically Sign & Open Account")
                }
                .font(.custom("Inter-SemiBold", size: 14))
                .foregroundStyle(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 12).fill(MilliColors.cyanGlow))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private func reviewRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.custom("Inter-Regular", size: 12))
                .foregroundStyle(MilliColors.textSecondary)
            Spacer()
            Text(value)
                .font(.custom("Inter-SemiBold", size: 12))
                .foregroundStyle(MilliColors.textPrimary)
        }
    }
}

// MARK: - RetirementPlanningStore Extension & Snapshots

@MainActor
public final class RetirementPlanningStore: ObservableObject {
    @Published public var currentAge: Int = 32 { didSet { persist() } }
    @Published public var currentBalance: Double = 42685.73 { didSet { persist() } }
    @Published public var annualIncome: Double = 75000 { didSet { persist() } }
    @Published public var contributionMode: RetirementContributionMode = .percentOfIncome { didSet { persist() } }
    @Published public var contributionPercent: Double = 15 { didSet { persist() } }
    @Published public var monthlyContribution: Double = 937.50 { didSet { persist() } }
    @Published public var targetRetirementAge: Int = 62 { didSet { persist() } }
    @Published public var annualReturnPercent: Double = 7.5 { didSet { persist() } }
    @Published public var milliAccount: MilliRetirementAccount? = MilliRetirementAccount.standard { didSet { persist() } }
    @Published public var mergedAccounts: [ConnectedExternalRetirementAccount] = [
        ConnectedExternalRetirementAccount(
            id: "merged-1",
            custodianName: "Fidelity Investments",
            accountType: "401(k)",
            nickname: "Past Employer 401(k)",
            balance: 34850.0,
            monthlyContribution: 0.0,
            annualReturnPercent: 7.5,
            rolloverStatus: .completed,
            accountMask: "8102"
        ),
        ConnectedExternalRetirementAccount(
            id: "merged-2",
            custodianName: "Vanguard",
            accountType: "Traditional IRA",
            nickname: "Vanguard IRA",
            balance: 18420.0,
            monthlyContribution: 200.0,
            annualReturnPercent: 7.5,
            rolloverStatus: .transferInitiated,
            accountMask: "3319"
        )
    ] { didSet { persist() } }
    @Published public private(set) var hasVerifiedConnectedData: Bool = true

    private let defaults = UserDefaults.standard
    private let storageKey = "milli_retirement_planning_profile_v3"
    private var isLoading = true

    public init() {
        load()
        isLoading = false
    }

    public var snapshot: RetirementPlanningSnapshot {
        RetirementPlanningSnapshot(
            currentAge: currentAge,
            currentBalance: currentBalance,
            annualIncome: annualIncome,
            contributionMode: contributionMode,
            contributionPercent: contributionPercent,
            monthlyContribution: monthlyContribution,
            targetRetirementAge: targetRetirementAge,
            annualReturnPercent: annualReturnPercent,
            hasVerifiedConnectedData: hasVerifiedConnectedData
        )
    }

    public func openMilliAccount(_ account: MilliRetirementAccount) {
        milliAccount = account
        hasVerifiedConnectedData = true
    }

    public func addMergedAccount(_ account: ConnectedExternalRetirementAccount) {
        mergedAccounts.append(account)
        hasVerifiedConnectedData = true
    }

    public func persist() {
        guard !isLoading else { return }
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(RetirementPlanningSnapshot.self, from: data) else {
            return
        }
        currentAge = saved.currentAge
        currentBalance = saved.currentBalance
        annualIncome = saved.annualIncome
        contributionMode = saved.contributionMode
        contributionPercent = saved.contributionPercent
        monthlyContribution = saved.monthlyContribution
        targetRetirementAge = saved.targetRetirementAge
        annualReturnPercent = saved.annualReturnPercent
        hasVerifiedConnectedData = saved.hasVerifiedConnectedData
    }
}

// MARK: - RetirementProjection & Calculator

public struct RetirementProjection {
    public let retirementYear: Int
    public let endingBalance: Double
    public let totalContributions: Double
    public let totalGrowth: Double
    public let points: [RetirementProjectionPoint]
}

public struct RetirementProjectionPoint: Identifiable {
    public let id = UUID()
    public let year: Int
    public let totalContributions: Double
    public let balance: Double
}

public enum RetirementProjectionCalculator {
    public static func calculate(profile: RetirementPlanningSnapshot, consolidatedBalance: Double) -> RetirementProjection? {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearsToRetirement = profile.targetRetirementAge - profile.currentAge
        guard yearsToRetirement > 0 else { return nil }

        let retirementYear = currentYear + yearsToRetirement
        let monthlyContribution = profile.annualIncome * (profile.contributionPercent / 100) / 12

        let annualReturn = profile.annualReturnPercent / 100
        let monthlyRate = annualReturn == 0 ? 0 : pow(1 + annualReturn, 1.0 / 12.0) - 1
        let totalMonths = yearsToRetirement * 12

        var balance = consolidatedBalance
        var userContributions = consolidatedBalance
        var annualPoints: [RetirementProjectionPoint] = [
            RetirementProjectionPoint(
                year: currentYear,
                totalContributions: userContributions,
                balance: balance
            )
        ]

        for month in 1...totalMonths {
            balance = balance * (1 + monthlyRate) + monthlyContribution
            userContributions += monthlyContribution

            if month % 12 == 0 || month == totalMonths {
                let yearOffset = Int(ceil(Double(month) / 12.0))
                annualPoints.append(
                    RetirementProjectionPoint(
                        year: currentYear + yearOffset,
                        totalContributions: userContributions,
                        balance: balance
                    )
                )
            }
        }

        let strideSize = max(annualPoints.count / 12, 1)
        var sampled = Array(annualPoints.enumerated().compactMap { index, point in
            index % strideSize == 0 ? point : nil
        })
        if let final = annualPoints.last, sampled.last?.year != final.year {
            sampled.append(final)
        }

        return RetirementProjection(
            retirementYear: retirementYear,
            endingBalance: balance,
            totalContributions: userContributions,
            totalGrowth: max(balance - userContributions, 0),
            points: sampled
        )
    }
}

// MARK: - Inputs Sheet

private struct RetirementInputsSheet: View {
    @ObservedObject var profile: RetirementPlanningStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CURRENT AGE")
                            .font(.custom("Inter-Bold", size: 10))
                            .foregroundStyle(MilliColors.textSecondary)
                        TextField("32", value: $profile.currentAge, format: .number)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(MilliColors.graphiteSurface))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TARGET RETIREMENT AGE")
                            .font(.custom("Inter-Bold", size: 10))
                            .foregroundStyle(MilliColors.textSecondary)
                        TextField("62", value: $profile.targetRetirementAge, format: .number)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(MilliColors.graphiteSurface))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("EXPECTED ANNUAL RETURN (%)")
                            .font(.custom("Inter-Bold", size: 10))
                            .foregroundStyle(MilliColors.textSecondary)
                        TextField("7.5", value: $profile.annualReturnPercent, format: .number)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(MilliColors.graphiteSurface))
                    }
                }
                .padding(16)
            }
            .background(MilliColors.background.ignoresSafeArea())
            .navigationTitle("Retirement Assumptions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
    }
}

// MARK: - Snapshot & Contribution Mode Models

public enum RetirementContributionMode: String, Codable, CaseIterable {
    case percentOfIncome
    case fixedMonthly
}

public struct RetirementPlanningSnapshot: Codable, Equatable {
    public let currentAge: Int
    public let currentBalance: Double
    public let annualIncome: Double
    public let contributionMode: RetirementContributionMode
    public let contributionPercent: Double
    public let monthlyContribution: Double
    public let targetRetirementAge: Int
    public let annualReturnPercent: Double
    public let hasVerifiedConnectedData: Bool

    public var isProjectionReady: Bool {
        currentAge > 0 && targetRetirementAge > currentAge
    }
}
