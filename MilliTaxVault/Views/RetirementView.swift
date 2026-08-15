import SwiftUI
import Charts

// MARK: - RetirementAccount Model
struct RetirementAccount: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var type: String
    var currentBalance: Double
    var monthlyContribution: Double
    var annualReturn: Double // as decimal, e.g. 0.07
}

// MARK: - RetirementView — Interactive Projected Retirement & Contributions
struct RetirementView: View {
    
    @State private var targetRetirementAge: Double = 65
    @State private var currentAge: Double = 30
    @State private var accounts: [RetirementAccount] = [
        RetirementAccount(name: "Milli Tax Vault", type: "Roth IRA", currentBalance: 28000, monthlyContribution: 450, annualReturn: 0.07),
        RetirementAccount(name: "Primary Checking", type: "Brokerage", currentBalance: 17000, monthlyContribution: 200, annualReturn: 0.05),
    ]
    @State private var showAddSheet = false
    @State private var projectionData: [RetirementProjectionPoint] = []
    
    // Computed values
    private var yearsToRetirement: Double {
        max(targetRetirementAge - currentAge, 1)
    }
    
    private var totalProjectedBalance: Double {
        accounts.reduce(0) { total, account in
            let years = yearsToRetirement
            let r = account.annualReturn
            let futureBalance = account.currentBalance * pow(1 + r, years)
            let futureContributions = account.monthlyContribution * 12 * (pow(1 + r, years) - 1) / max(r, 0.001)
            return total + futureBalance + futureContributions
        }
    }
    
    private var estimatedMonthlyIncome: Double {
        totalProjectedBalance * 0.04 / 12
    }
    
    private var goalPercentage: Double {
        min(totalProjectedBalance / 2_500_000, 1.0)
    }
    
    var body: some View {
        VStack(spacing: MilliLayout.sectionGap) {
            // Projected Monthly Income — hero number
            monthlyIncomeHero
            
            // Interactive Projection Chart + Slider
            projectionChartCard
            
            // Contribution Summary
            contributionSummaryCard
            
            // Accounts Included
            accountsSection
            
            // Roth vs Traditional
            rothComparisonRow
            
            // Tax Savings
            taxSavingsCard
        }
        .padding(.horizontal, MilliLayout.screenMargin)
        .padding(.top, 60)
        .onAppear { rebuildProjection() }
        .onChange(of: targetRetirementAge) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                rebuildProjection()
            }
        }
        .onChange(of: accounts) { _, _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                rebuildProjection()
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddRetirementAccountSheet { newAccount in
                accounts.append(newAccount)
            }
        }
    }
    
    // MARK: - Monthly Income Hero
    private var monthlyIncomeHero: some View {
        VStack(spacing: 6) {
            Text("EST. MONTHLY INCOME IN RETIREMENT")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .tracking(0.5)
            
            Text(formatCurrency(estimatedMonthlyIncome) + "/mo")
                .font(.system(size: 32, weight: .black))
                .foregroundStyle(MilliColors.cyan)
                .contentTransition(.numericText())
            
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("Lump Sum")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(MilliColors.textMuted)
                    Text(formatCompact(totalProjectedBalance))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 24)
                
                VStack(spacing: 2) {
                    Text("Retire at")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(MilliColors.textMuted)
                    Text("\(Int(targetRetirementAge))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 24)
                
                VStack(spacing: 2) {
                    Text("4% Rule")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(MilliColors.textMuted)
                    Text("Safe W/D")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .milliSurface(hasCyanBorder: true)
    }
    
    // MARK: - Projection Chart + Slider
    private var projectionChartCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("GROWTH PROJECTION")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.5)
                Spacer()
                Text("Age \(Int(currentAge)) → \(Int(targetRetirementAge))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MilliColors.textMuted)
            }
            
            // Chart
            Chart(projectionData) { point in
                AreaMark(
                    x: .value("Age", point.age),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.cyan.opacity(0.25), MilliColors.cyan.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
                
                LineMark(
                    x: .value("Age", point.age),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(MilliColors.cyan)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.system(size: 9))
                                .foregroundStyle(MilliColors.textMuted)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(formatCompact(val))
                                .font(.system(size: 9))
                                .foregroundStyle(MilliColors.textMuted)
                        }
                    }
                }
            }
            .frame(height: 160)
            
            // Retirement Age Slider
            VStack(spacing: 4) {
                HStack {
                    Text("50")
                        .font(.system(size: 10))
                        .foregroundStyle(MilliColors.textMuted)
                    
                    Slider(value: $targetRetirementAge, in: 50...75, step: 1)
                        .tint(MilliColors.cyan)
                    
                    Text("75")
                        .font(.system(size: 10))
                        .foregroundStyle(MilliColors.textMuted)
                }
                
                Text("Target Retirement Age: \(Int(targetRetirementAge))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MilliColors.textSecondary)
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
    
    // MARK: - Contribution Summary
    private var contributionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTRIBUTIONS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MilliColors.textSecondary)
                .tracking(0.5)
            
            let totalMonthly = accounts.reduce(0) { $0 + $1.monthlyContribution }
            let totalYTD = totalMonthly * 12
            
            HStack(spacing: 0) {
                contributionMetric(label: "Monthly", value: formatCurrency(totalMonthly))
                Spacer()
                contributionMetric(label: "YTD Total", value: formatCurrency(totalYTD))
                Spacer()
                contributionMetric(label: "Accounts", value: "\(accounts.count)")
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
    
    private func contributionMetric(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MilliColors.textMuted)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
    
    // MARK: - Accounts Section
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ACCOUNTS INCLUDED")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.5)
                Spacer()
                Button(action: { showAddSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("Add Account")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(MilliColors.cyan)
                }
                .buttonStyle(.plain)
            }
            
            ForEach(accounts) { account in
                accountRow(account)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            withAnimation(.spring()) {
                                accounts.removeAll { $0.id == account.id }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    private func accountRow(_ account: RetirementAccount) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyan.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: iconForType(account.type))
                    .font(.system(size: 13))
                    .foregroundStyle(MilliColors.cyan)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(account.type)
                    .font(.system(size: 10))
                    .foregroundStyle(MilliColors.textMuted)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(account.currentBalance))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text("+\(formatCurrency(account.monthlyContribution))/mo")
                    .font(.system(size: 10))
                    .foregroundStyle(MilliColors.cyan.opacity(0.8))
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, 12)
        .milliSurface()
    }
    
    // MARK: - Roth vs Traditional
    private var rothComparisonRow: some View {
        HStack(spacing: 12) {
            comparisonPill(title: "Roth IRA", subtitle: "Tax-free growth", icon: "arrow.up.right.circle.fill")
            comparisonPill(title: "Traditional", subtitle: "Tax-deferred", icon: "building.columns.fill")
        }
    }
    
    private func comparisonPill(title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(MilliColors.cyan)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(MilliColors.textMuted)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .milliSurface()
    }
    
    // MARK: - Tax Savings Card
    private var taxSavingsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(MilliColors.cyan)
                Text("TAX SAVINGS FROM RETIREMENT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.5)
            }
            
            let annualContrib = accounts.reduce(0) { $0 + $1.monthlyContribution } * 12
            let estimatedSavings = annualContrib * 0.22 // 22% marginal tax bracket
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatCurrency(estimatedSavings))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Estimated annual tax reduction")
                        .font(.system(size: 11))
                        .foregroundStyle(MilliColors.textMuted)
                }
                Spacer()
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(MilliColors.cyan.opacity(0.3))
            }
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .milliSurface()
    }
    
    // MARK: - Helpers
    private func rebuildProjection() {
        var points: [RetirementProjectionPoint] = []
        let startAge = Int(currentAge)
        let endAge = Int(targetRetirementAge)
        
        for age in startAge...endAge {
            let yearsElapsed = Double(age - startAge)
            var totalAtAge: Double = 0
            
            for account in accounts {
                let r = account.annualReturn
                let balanceGrowth = account.currentBalance * pow(1 + r, yearsElapsed)
                let contribGrowth = account.monthlyContribution * 12 * (pow(1 + r, yearsElapsed) - 1) / max(r, 0.001)
                totalAtAge += balanceGrowth + contribGrowth
            }
            
            points.append(RetirementProjectionPoint(age: age, balance: totalAtAge))
        }
        
        projectionData = points
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return "$\(String(format: "%.1fM", value / 1_000_000))"
        } else if value >= 1000 {
            return "$\(String(format: "%.0fK", value / 1000))"
        }
        return "$\(Int(value))"
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "Roth IRA": return "arrow.up.right.circle.fill"
        case "Traditional IRA": return "building.columns.fill"
        case "401(k)": return "briefcase.fill"
        case "Pension": return "shield.fill"
        case "Brokerage": return "chart.line.uptrend.xyaxis"
        default: return "banknote.fill"
        }
    }
}

// MARK: - Data Model
struct RetirementProjectionPoint: Identifiable {
    let id = UUID()
    let age: Int
    let balance: Double
}

#Preview {
    ScrollView {
        RetirementView()
    }
    .background(MilliColors.obsidian)
}
