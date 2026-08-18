import SwiftUI
import Charts

// MARK: - RetirementView
// Retirement projections are generated only from user-supplied or verified connected
// data. No seeded balances, income, ages, or projected values are shown as user facts.

struct RetirementView: View {
    var onBack: () -> Void = {}

    @StateObject private var profile = RetirementPlanningStore()
    @State private var showInputs = false

    private var projection: RetirementProjection? {
        RetirementProjectionCalculator.calculate(profile: profile.snapshot)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                dataSourceCard

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
    }

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

    private var dataSourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PROJECTION DATA")
                    .sectionHeaderStyle()
                Spacer()
                Text(profile.hasVerifiedConnectedData ? "CONNECTED" : "MANUAL")
                    .font(MilliFont.caption)
                    .tracking(0.55)
                    .foregroundStyle(profile.hasVerifiedConnectedData ? MilliColors.positive : MilliColors.cyanGlow)
            }

            if profile.hasVerifiedConnectedData {
                HStack(spacing: 9) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(MilliColors.positive)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Using verified connected retirement data")
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("Balance and income inputs were supplied by an authenticated account connection.")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }
            } else {
                HStack(spacing: 9) {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(MilliColors.cyanGlow)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.snapshot.isProjectionReady ? "Using your saved planning inputs" : "Add your retirement inputs")
                            .font(MilliFont.bodyMedium)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("Milli will not estimate a retirement balance until your age, current balance, and contribution basis are known.")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                }
            }

            Button {
                showInputs = true
            } label: {
                HStack {
                    Image(systemName: profile.snapshot.isProjectionReady ? "pencil" : "plus")
                    Text(profile.snapshot.isProjectionReady ? "Edit Inputs" : "Add Retirement Data")
                }
                .font(MilliFont.labelLarge)
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.34), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
        }
        .milliCard(padding: 13)
    }

    private func hero(_ projection: RetirementProjection) -> some View {
        VStack(spacing: 8) {
            Text("Projected retirement year")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            Text(String(projection.retirementYear))
                .font(.custom("Sora-Bold", size: 48, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .contentTransition(.numericText())

            Text("at age \(profile.targetRetirementAge)")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)

            HStack(spacing: 0) {
                heroMetric(
                    "Contribution",
                    profile.contributionDisplay,
                    profile.contributionMode == .percentOfIncome ? "of entered income" : "per month"
                )
                Rectangle().fill(Color.white.opacity(0.06)).frame(width: 1, height: 46)
                heroMetric("Projected Value", compactCurrency(projection.endingBalance), "planning estimate")
            }
        }
        .milliCard(padding: 14)
    }

    private func heroMetric(_ title: String, _ value: String, _ subtitle: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.positive)
            Text(subtitle)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func projectionChart(_ projection: RetirementProjection) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PROJECTED GROWTH")
                        .sectionHeaderStyle()
                    Text("Based on your current inputs")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text("\(profile.targetRetirementAge) target age")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart {
                ForEach(projection.points) { point in
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Total Projection", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow.opacity(0.23), MilliColors.cyanGlow.opacity(0.015)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Total Projection", point.balance),
                        series: .value("Series", "Total Projection")
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .lineStyle(StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Investment Growth", point.investmentGrowth),
                        series: .value("Series", "Investment Growth")
                    )
                    .foregroundStyle(Color.white.opacity(0.84))
                    .lineStyle(StrokeStyle(lineWidth: 1.55, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Contributions", point.totalContributions),
                        series: .value("Series", "Your Contributions")
                    )
                    .foregroundStyle(MilliColors.deepCyan)
                    .lineStyle(StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXScale(domain: chartYearDomain(projection))
            .chartYScale(domain: 0...chartMaximum(projection))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(compactCurrency(amount))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisValueLabel {
                        if let year = value.as(Int.self) {
                            Text(String(year))
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .frame(height: 210)

            HStack(spacing: 12) {
                legend(MilliColors.cyanGlow, "Projection")
                legend(Color.white.opacity(0.84), "Growth")
                legend(MilliColors.deepCyan, "Contributions")
            }
        }
        .milliCard(padding: 14)
    }

    private func chartYearDomain(_ projection: RetirementProjection) -> ClosedRange<Int> {
        let first = projection.points.first?.year ?? projection.retirementYear - 1
        let last = projection.points.last?.year ?? projection.retirementYear
        return first...max(last, first + 1)
    }

    private func chartMaximum(_ projection: RetirementProjection) -> Double {
        max(projection.endingBalance * 1.08, 1)
    }

    private func legend(_ color: Color, _ title: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(title)
                .font(.custom("Inter-Regular", size: 8.2, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textSecondary)
        }
    }

    private var planControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("ADJUST YOUR PLAN")
                    .sectionHeaderStyle()
                Spacer()
                Button("Inputs") { showInputs = true }
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            if profile.contributionMode == .percentOfIncome {
                sliderRow(
                    title: "Contribution Percentage",
                    value: $profile.contributionPercent,
                    range: 0...50,
                    suffix: "%"
                )
            } else {
                VStack(spacing: 7) {
                    HStack {
                        Text("Monthly Contribution")
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textSecondary)
                        Spacer()
                        Text(profile.monthlyContribution.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                    }
                    Slider(value: $profile.monthlyContribution, in: 0...5_000, step: 25)
                        .tint(MilliColors.cyanGlow)
                }
            }

            sliderRow(
                title: "Retirement Age",
                value: Binding(
                    get: { Double(profile.targetRetirementAge) },
                    set: { profile.targetRetirementAge = Int($0.rounded()) }
                ),
                range: Double(max(profile.currentAge + 1, 18))...80,
                suffix: ""
            )
        }
        .milliCard(padding: 14)
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(title)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer()
                Text("\(Int(value.wrappedValue))\(suffix)")
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            Slider(value: value, in: range, step: 1)
                .tint(MilliColors.cyanGlow)
        }
    }

    private func projectionSummary(_ projection: RetirementProjection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("UPDATED PROJECTION")
                .sectionHeaderStyle()

            HStack(spacing: 8) {
                summary("Retirement Year", String(projection.retirementYear))
                summary("Projected Value", compactCurrency(projection.endingBalance))
            }
            HStack(spacing: 8) {
                summary("Your Contributions", compactCurrency(projection.totalContributions))
                summary("Projected Growth", compactCurrency(projection.totalGrowth))
            }
        }
    }

    private func summary(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericSmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .milliCard(padding: 10)
    }

    private var assumptionsCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("ASSUMPTIONS")
                    .sectionHeaderStyle()
                Spacer()
                Button("Edit") { showInputs = true }
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            assumptionRow("Current age", String(profile.currentAge))
            assumptionRow("Current retirement balance", profile.currentBalance.formatted(.currency(code: "USD").precision(.fractionLength(0))))
            if profile.contributionMode == .percentOfIncome {
                assumptionRow("Annual income basis", profile.annualIncome.formatted(.currency(code: "USD").precision(.fractionLength(0))))
            } else {
                assumptionRow("Monthly contribution", profile.monthlyContribution.formatted(.currency(code: "USD").precision(.fractionLength(0))))
            }
            assumptionRow("Annual return assumption", String(format: "%.1f%%", profile.annualReturnPercent))

            Text("This is a planning projection, not a guaranteed future balance. Changing income, contributions, investment performance, fees, taxes, withdrawals, or retirement age will change the result.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .milliCard(padding: 13)
    }

    private func assumptionRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
            Spacer()
            Text(value)
                .font(MilliFont.bodySmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
        }
    }

    private var emptyProjectionState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text("No retirement projection yet")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)

            Text("Add your current age, retirement balance, and either annual income or a fixed monthly contribution. Milli will calculate the projection from those values instead of assuming a generic income or balance.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showInputs = true
            } label: {
                Text("Set Up Retirement Projection")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.blackGlass)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(MilliColors.cyanGlow)
                    )
            }
            .buttonStyle(.plain)
        }
        .milliCard(padding: 18)
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.2fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

// MARK: - Inputs

private struct RetirementInputsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var profile: RetirementPlanningStore

    @State private var ageText = ""
    @State private var balanceText = ""
    @State private var incomeText = ""
    @State private var monthlyText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("RETIREMENT INPUTS")
                                .sectionHeaderStyle()
                            Text("Use your actual current values so Milli can calculate a meaningful projection.")
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textSecondary)
                        }

                        inputSection("CURRENT PROFILE") {
                            inputField("Current age", text: $ageText, keyboard: .numberPad)
                            inputField("Current retirement balance", text: $balanceText, keyboard: .decimalPad, prefix: "$")
                        }

                        inputSection("CONTRIBUTION BASIS") {
                            Picker("Contribution mode", selection: $profile.contributionMode) {
                                ForEach(RetirementContributionMode.allCases, id: \.self) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            if profile.contributionMode == .percentOfIncome {
                                inputField("Annual income used for retirement contributions", text: $incomeText, keyboard: .decimalPad, prefix: "$")

                                HStack {
                                    Text("Contribution percentage")
                                        .font(MilliFont.bodySmall)
                                        .foregroundStyle(MilliColors.textSecondary)
                                    Spacer()
                                    Text("\(Int(profile.contributionPercent))%")
                                        .font(MilliFont.numericSmall)
                                        .foregroundStyle(MilliColors.textPrimary)
                                }
                                Slider(value: $profile.contributionPercent, in: 0...50, step: 1)
                                    .tint(MilliColors.cyanGlow)
                            } else {
                                inputField("Monthly retirement contribution", text: $monthlyText, keyboard: .decimalPad, prefix: "$")
                            }
                        }

                        inputSection("PROJECTION ASSUMPTIONS") {
                            HStack {
                                Text("Target retirement age")
                                    .font(MilliFont.bodySmall)
                                    .foregroundStyle(MilliColors.textSecondary)
                                Spacer()
                                Text(String(profile.targetRetirementAge))
                                    .font(MilliFont.numericSmall)
                                    .foregroundStyle(MilliColors.textPrimary)
                            }
                            Slider(
                                value: Binding(
                                    get: { Double(profile.targetRetirementAge) },
                                    set: { profile.targetRetirementAge = Int($0.rounded()) }
                                ),
                                in: Double(max(profile.currentAge + 1, 18))...80,
                                step: 1
                            )
                            .tint(MilliColors.cyanGlow)

                            HStack {
                                Text("Assumed annual return")
                                    .font(MilliFont.bodySmall)
                                    .foregroundStyle(MilliColors.textSecondary)
                                Spacer()
                                Text(String(format: "%.1f%%", profile.annualReturnPercent))
                                    .font(MilliFont.numericSmall)
                                    .foregroundStyle(MilliColors.textPrimary)
                            }
                            Slider(value: $profile.annualReturnPercent, in: 0...12, step: 0.5)
                                .tint(MilliColors.cyanGlow)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Label("Connected accounts", systemImage: "link")
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("When a verified retirement or investment account connection supplies a current balance, Milli can use that value instead of manual entry. Connected income can likewise become the contribution basis once authenticated transaction or payroll data is available. No connection is represented here until one is actually verified.")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .milliCard(padding: 12)
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 14)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Retirement Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        applyInputs()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadFields)
    }

    private func inputSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title).sectionHeaderStyle()
            VStack(spacing: 9) { content() }
                .milliCard(padding: 12)
        }
    }

    private func inputField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType, prefix: String? = nil) -> some View {
        HStack(spacing: 7) {
            if let prefix {
                Text(prefix)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            TextField(title, text: text)
                .keyboardType(keyboard)
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textPrimary)
                .tint(MilliColors.cyanGlow)
        }
        .padding(.horizontal, 11)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                }
        )
    }

    private func loadFields() {
        ageText = profile.currentAge > 0 ? String(profile.currentAge) : ""
        balanceText = profile.currentBalance > 0 ? String(format: "%.0f", profile.currentBalance) : ""
        incomeText = profile.annualIncome > 0 ? String(format: "%.0f", profile.annualIncome) : ""
        monthlyText = profile.monthlyContribution > 0 ? String(format: "%.0f", profile.monthlyContribution) : ""
    }

    private func applyInputs() {
        profile.currentAge = Int(cleanNumber(ageText)) ?? 0
        profile.currentBalance = Double(cleanNumber(balanceText)) ?? 0
        profile.annualIncome = Double(cleanNumber(incomeText)) ?? 0
        profile.monthlyContribution = Double(cleanNumber(monthlyText)) ?? 0
        if profile.targetRetirementAge <= profile.currentAge {
            profile.targetRetirementAge = min(max(profile.currentAge + 1, 18), 80)
        }
        profile.persist()
    }

    private func cleanNumber(_ value: String) -> String {
        value
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Persistent planning state

enum RetirementContributionMode: String, Codable, CaseIterable {
    case percentOfIncome
    case fixedMonthly

    var label: String {
        switch self {
        case .percentOfIncome: return "% of Income"
        case .fixedMonthly: return "Fixed Monthly"
        }
    }
}

private struct RetirementPlanningSnapshot: Codable {
    var currentAge: Int
    var currentBalance: Double
    var annualIncome: Double
    var contributionMode: RetirementContributionMode
    var contributionPercent: Double
    var monthlyContribution: Double
    var targetRetirementAge: Int
    var annualReturnPercent: Double
    var hasVerifiedConnectedData: Bool

    var isProjectionReady: Bool {
        guard currentAge >= 18,
              currentBalance >= 0,
              targetRetirementAge > currentAge,
              annualReturnPercent >= 0 else {
            return false
        }

        switch contributionMode {
        case .percentOfIncome:
            return annualIncome > 0 && contributionPercent >= 0
        case .fixedMonthly:
            return monthlyContribution >= 0
        }
    }
}

@MainActor
private final class RetirementPlanningStore: ObservableObject {
    @Published var currentAge: Int = 0 { didSet { persist() } }
    @Published var currentBalance: Double = 0 { didSet { persist() } }
    @Published var annualIncome: Double = 0 { didSet { persist() } }
    @Published var contributionMode: RetirementContributionMode = .percentOfIncome { didSet { persist() } }
    @Published var contributionPercent: Double = 15 { didSet { persist() } }
    @Published var monthlyContribution: Double = 0 { didSet { persist() } }
    @Published var targetRetirementAge: Int = 65 { didSet { persist() } }
    @Published var annualReturnPercent: Double = 7 { didSet { persist() } }
    @Published private(set) var hasVerifiedConnectedData: Bool = false

    private let defaults = UserDefaults.standard
    private let storageKey = "milli_retirement_planning_profile_v2"
    private var isLoading = true

    init() {
        load()
        isLoading = false
    }

    var snapshot: RetirementPlanningSnapshot {
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

    var contributionDisplay: String {
        switch contributionMode {
        case .percentOfIncome:
            return "\(Int(contributionPercent))%"
        case .fixedMonthly:
            return monthlyContribution.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        }
    }

    func persist() {
        guard !isLoading,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
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

// MARK: - Projection calculator

private struct RetirementProjection {
    let retirementYear: Int
    let endingBalance: Double
    let totalContributions: Double
    let totalGrowth: Double
    let points: [RetirementProjectionPoint]
}

private struct RetirementProjectionPoint: Identifiable {
    let id = UUID()
    let year: Int
    let totalContributions: Double
    let balance: Double

    var investmentGrowth: Double {
        max(balance - totalContributions, 0)
    }
}

private enum RetirementProjectionCalculator {
    static func calculate(profile: RetirementPlanningSnapshot) -> RetirementProjection? {
        guard profile.isProjectionReady else { return nil }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearsToRetirement = profile.targetRetirementAge - profile.currentAge
        guard yearsToRetirement > 0 else { return nil }

        let retirementYear = currentYear + yearsToRetirement
        let monthlyContribution: Double
        switch profile.contributionMode {
        case .percentOfIncome:
            monthlyContribution = profile.annualIncome * (profile.contributionPercent / 100) / 12
        case .fixedMonthly:
            monthlyContribution = profile.monthlyContribution
        }

        let annualReturn = profile.annualReturnPercent / 100
        let monthlyRate = annualReturn == 0 ? 0 : pow(1 + annualReturn, 1.0 / 12.0) - 1
        let totalMonths = yearsToRetirement * 12

        var balance = profile.currentBalance
        var userContributions = profile.currentBalance
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
