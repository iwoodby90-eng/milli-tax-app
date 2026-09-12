import SwiftUI
import Charts
import UIKit

// MARK: - ReportsView
// High-fidelity reporting surface with readable cash-flow analytics and working
// local PDF/CSV export. The reference model is deterministic until live reporting
// repositories replace it.

struct ReportsView: View {
    var onBack: () -> Void = {}

    @State private var selectedTab = ReportTab.overview
    @State private var sharePayload: ReportSharePayload?

    private let report = ReportDataModel.reference

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                header
                tabs
                selectedContent
                exportActions
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, MilliSpacing.bottomContentClearance + 18)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(item: $sharePayload) { payload in
            ReportActivityView(items: [payload.url])
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.white.opacity(0.045)))
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.7))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Reports")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("Cash flow, deductions, and mileage")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Button {
                exportPDFAndShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))
                    .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.24), lineWidth: 0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share current report")
        }
        .frame(maxWidth: .infinity)
    }

    private var tabs: some View {
        HStack(spacing: 4) {
            ForEach(ReportTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.title)
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(selectedTab == tab ? MilliColors.blackGlass : MilliColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(selectedTab == tab ? MilliColors.cyanGlow : Color.white.opacity(0.025))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(
                                    selectedTab == tab ? Color.white.opacity(0.48) : Color.white.opacity(0.07),
                                    lineWidth: 0.7
                                )
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.28))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.7)
                }
        )
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .deductions:
            deductionsContent
        case .trips:
            tripsContent
        }
    }

    // MARK: Overview

    private var overviewContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                overviewMetric("GROSS INCOME", currency(report.grossIncome), MilliColors.textPrimary)
                overviewMetric("DEDUCTIONS", currency(report.totalDeductions), MilliColors.warning)
            }

            HStack(spacing: 10) {
                overviewMetric("BUSINESS MILES", "\(Int(report.businessMiles).formatted()) mi", MilliColors.textPrimary)
                overviewMetric("EST. TAX SAVED", currency(report.estimatedTaxSavings), MilliColors.positive)
            }

            monthlyActivityCard
        }
    }

    private var monthlyActivityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("MONTHLY CASH FLOW")
                        .sectionHeaderStyle()
                    Text("Income sources, operating expenses, and tax protection")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer(minLength: 8)

                Text(report.periodLabel)
                    .font(MilliFont.labelLarge)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textSecondary)
            }

            cashFlowLegend

            Chart {
                ForEach(report.months) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Payout income", point.payoutIncome)
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .lineStyle(StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Month", point.month),
                        y: .value("Payout income", point.payoutIncome)
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .symbolSize(34)

                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Cash in", point.cashIncome)
                    )
                    .foregroundStyle(MilliColors.silverBright)
                    .lineStyle(StrokeStyle(lineWidth: 2.0, lineCap: .round, dash: [6, 4]))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Month", point.month),
                        y: .value("Cash in", point.cashIncome)
                    )
                    .foregroundStyle(MilliColors.silverBright)
                    .symbolSize(28)

                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Expenses", point.expenses)
                    )
                    .foregroundStyle(MilliColors.warning)
                    .lineStyle(StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Month", point.month),
                        y: .value("Expenses", point.expenses)
                    )
                    .foregroundStyle(MilliColors.warning)
                    .symbolSize(30)

                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Tax reserved", point.taxReserved)
                    )
                    .foregroundStyle(MilliColors.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.linear)

                    PointMark(
                        x: .value("Month", point.month),
                        y: .value("Tax reserved", point.taxReserved)
                    )
                    .foregroundStyle(MilliColors.positive)
                    .symbolSize(30)
                }
            }
            .chartYScale(domain: 0...2600)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0.0, 500.0, 1000.0, 1500.0, 2000.0, 2500.0]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.7, dash: [3, 5]))
                        .foregroundStyle(Color.white.opacity(0.07))
                    AxisTick()
                        .foregroundStyle(Color.white.opacity(0.12))
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: report.months.map(\.month)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.6, dash: [2, 6]))
                        .foregroundStyle(Color.white.opacity(0.045))
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(MilliColors.textSecondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 245)
            .accessibilityLabel("Monthly cash flow chart showing payout income, cash income, expenses, and tax reserved")

            Divider()
                .overlay(Color.white.opacity(0.07))

            HStack(spacing: 0) {
                cashFlowTotal("INCOME", value: report.grossIncome, color: MilliColors.cyanGlow)
                Divider().frame(height: 38).overlay(Color.white.opacity(0.08))
                cashFlowTotal("EXPENSES", value: report.totalDeductions, color: MilliColors.warning)
                Divider().frame(height: 38).overlay(Color.white.opacity(0.08))
                cashFlowTotal("TAX RESERVED", value: report.totalTaxReserved, color: MilliColors.positive)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0D171C"), Color(hex: "071013")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.20), MilliColors.cyanGlow.opacity(0.18), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.055), radius: 18, y: 7)
        )
    }

    private var cashFlowLegend: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 8
        ) {
            legendItem("Payouts", color: MilliColors.cyanGlow, detail: "Gig-platform deposits")
            legendItem("Cash In", color: MilliColors.silverBright, detail: "Other income")
            legendItem("Expenses", color: MilliColors.warning, detail: "Business spend")
            legendItem("Tax Reserved", color: MilliColors.positive, detail: "Protected for taxes")
        }
    }

    private func legendItem(_ title: String, color: Color, detail: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.35), radius: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(MilliColors.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private func cashFlowTotal(_ title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(MilliColors.textTertiary)
            Text(value.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }

    private func overviewMetric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .tracking(0.55)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, minHeight: 78, alignment: .leading)
        .milliCard(padding: 13)
    }

    // MARK: Deductions

    private var deductionsContent: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL DEDUCTIONS")
                        .sectionHeaderStyle()
                    Text(currency(report.totalDeductions))
                        .font(MilliFont.numericLarge)
                        .monospacedDigit()
                        .foregroundStyle(MilliColors.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("DEDUCTION RATE")
                        .font(MilliFont.sectionLabel)
                        .foregroundStyle(MilliColors.textSecondary)
                    Text(report.deductionRate.formatted(.percent.precision(.fractionLength(1))))
                        .font(MilliFont.labelLarge)
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text(report.periodLabel)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
            .milliCard(padding: 16)

            deductionsChart
            categoryList
        }
    }

    private var deductionsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BUSINESS EXPENSES BY MONTH")
                        .sectionHeaderStyle()
                    Text("Deductible operating spend")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
                Spacer()
                Text(report.periodLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart(report.months) { point in
                BarMark(
                    x: .value("Month", point.month),
                    y: .value("Amount", point.expenses)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.warning, MilliColors.warning.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.055))
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(height: 205)
        }
        .milliCard(padding: 16)
    }

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TOP DEDUCTION CATEGORIES")
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                ForEach(Array(report.categories.enumerated()), id: \.element.id) { index, category in
                    HStack(spacing: 10) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(category.color)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(category.color.opacity(0.10)))

                        Text(category.name)
                            .font(MilliFont.bodySmall)
                            .foregroundStyle(MilliColors.textPrimary)

                        Spacer()

                        Text(currency(category.amount))
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)

                        Text(category.share.formatted(.percent.precision(.fractionLength(1))))
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)

                    if index < report.categories.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.05))
                            .padding(.leading, 52)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    // MARK: Trips

    private var tripsContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                overviewMetric("BUSINESS MILES", "\(Int(report.businessMiles).formatted()) mi", MilliColors.textPrimary)
                overviewMetric("MILEAGE VALUE", currency(report.mileageDeduction), MilliColors.positive)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT BUSINESS TRIPS")
                    .sectionHeaderStyle()

                VStack(spacing: 0) {
                    ForEach(Array(report.trips.enumerated()), id: \.element.id) { index, trip in
                        HStack(spacing: 10) {
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MilliColors.cyanGlow)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.platform)
                                    .font(MilliFont.headlineSmall)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(trip.dateLabel)
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.textTertiary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(trip.miles.formatted(.number.precision(.fractionLength(1)))) mi")
                                    .font(MilliFont.numericSmall)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(currency(trip.deduction))
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.positive)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)

                        if index < report.trips.count - 1 {
                            Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 52)
                        }
                    }
                }
                .background(MilliCardBackground(showGlow: true))
            }
        }
    }

    // MARK: Export

    private var exportActions: some View {
        HStack(spacing: 10) {
            exportButton("Export PDF", icon: "doc.richtext", action: exportPDFAndShare)
            exportButton("Export CSV", icon: "tablecells", action: exportCSVAndShare)
        }
    }

    private func exportButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(MilliFont.labelLarge)
            }
            .foregroundStyle(MilliColors.cyanGlow)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(MilliColors.focusedBorder, lineWidth: 0.7)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    private func exportCSVAndShare() {
        do {
            let url = try ReportExporter.csvURL(report: report, selectedTab: selectedTab)
            sharePayload = ReportSharePayload(url: url)
        } catch {
            assertionFailure("Failed to create CSV report: \(error)")
        }
    }

    private func exportPDFAndShare() {
        do {
            let url = try ReportExporter.pdfURL(report: report, selectedTab: selectedTab)
            sharePayload = ReportSharePayload(url: url)
        } catch {
            assertionFailure("Failed to create PDF report: \(error)")
        }
    }

    private func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}

private enum ReportTab: String, CaseIterable {
    case overview
    case deductions
    case trips

    var title: String {
        rawValue.capitalized
    }
}

private struct ReportMonth: Identifiable {
    let id = UUID()
    let month: String
    let payoutIncome: Double
    let cashIncome: Double
    let expenses: Double
    let taxReserved: Double

    var income: Double { payoutIncome + cashIncome }
    var deductions: Double { expenses }
}

private struct ReportCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let share: Double
    let color: Color
    let icon: String
}

private struct BusinessTrip: Identifiable {
    let id = UUID()
    let platform: String
    let dateLabel: String
    let miles: Double
    let deduction: Double
}

private struct ReportDataModel {
    let grossIncome: Double
    let totalDeductions: Double
    let businessMiles: Double
    let mileageDeduction: Double
    let estimatedTaxSavings: Double
    let months: [ReportMonth]
    let categories: [ReportCategory]
    let trips: [BusinessTrip]

    var deductionRate: Double {
        guard grossIncome > 0 else { return 0 }
        return totalDeductions / grossIncome
    }

    var totalTaxReserved: Double {
        months.reduce(0) { $0 + $1.taxReserved }
    }

    var periodLabel: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    static let reference = ReportDataModel(
        grossIncome: 10_011.16,
        totalDeductions: 2_843.17,
        businessMiles: 4_112,
        mileageDeduction: 2_218.42,
        estimatedTaxSavings: 894.73,
        months: [
            .init(month: "Jan", payoutIncome: 1_120, cashIncome: 300, expenses: 410, taxReserved: 355),
            .init(month: "Feb", payoutIncome: 1_485, cashIncome: 400, expenses: 575, taxReserved: 471),
            .init(month: "Mar", payoutIncome: 1_840, cashIncome: 420, expenses: 720, taxReserved: 565),
            .init(month: "Apr", payoutIncome: 2_265, cashIncome: 450, expenses: 940, taxReserved: 679),
            .init(month: "May", payoutIncome: 1_511.16, cashIncome: 220, expenses: 198.17, taxReserved: 433)
        ],
        categories: [
            .init(name: "Fuel", amount: 1_286.45, share: 0.452, color: MilliColors.cyanGlow, icon: "fuelpump.fill"),
            .init(name: "Car Maintenance", amount: 642.17, share: 0.226, color: MilliColors.deepCyan, icon: "wrench.and.screwdriver.fill"),
            .init(name: "Insurance", amount: 389.45, share: 0.137, color: MilliColors.deepCyan, icon: "shield.fill"),
            .init(name: "Tolls & Parking", amount: 246.30, share: 0.086, color: MilliColors.warning, icon: "parkingsign.circle.fill"),
            .init(name: "Other", amount: 278.80, share: 0.099, color: MilliColors.textSecondary, icon: "ellipsis.circle.fill")
        ],
        trips: [
            .init(platform: "Spark Driver", dateLabel: "Today • 7:18 AM", miles: 12.4, deduction: 6.55),
            .init(platform: "DoorDash", dateLabel: "Yesterday • 6:42 PM", miles: 8.7, deduction: 4.59),
            .init(platform: "Uber", dateLabel: "Yesterday • 1:10 PM", miles: 18.2, deduction: 9.61),
            .init(platform: "Instacart", dateLabel: "2 days ago", miles: 14.6, deduction: 7.71)
        ]
    )
}

private struct ReportSharePayload: Identifiable {
    let id = UUID()
    let url: URL
}

private struct ReportActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum ReportExporter {
    static func csvURL(report: ReportDataModel, selectedTab: ReportTab) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Milli-\(selectedTab.title)-Report.csv")

        let csv: String
        switch selectedTab {
        case .overview:
            let monthlyRows = report.months.map {
                "\($0.month),\($0.payoutIncome),\($0.cashIncome),\($0.expenses),\($0.taxReserved)"
            }
            csv = ([
                "Metric,Value",
                "Gross Income,\(report.grossIncome)",
                "Total Deductions,\(report.totalDeductions)",
                "Business Miles,\(report.businessMiles)",
                "Mileage Deduction,\(report.mileageDeduction)",
                "Estimated Tax Savings,\(report.estimatedTaxSavings)",
                "Total Tax Reserved,\(report.totalTaxReserved)",
                "",
                "Month,Payout Income,Cash In,Expenses,Tax Reserved"
            ] + monthlyRows).joined(separator: "\n")

        case .deductions:
            let rows = report.categories.map { "\(csvEscape($0.name)),\($0.amount),\($0.share)" }
            csv = (["Category,Amount,Share"] + rows).joined(separator: "\n")

        case .trips:
            let rows = report.trips.map { "\(csvEscape($0.platform)),\(csvEscape($0.dateLabel)),\($0.miles),\($0.deduction)" }
            csv = (["Platform,Date,Miles,Deduction"] + rows).joined(separator: "\n")
        }

        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    static func pdfURL(report: ReportDataModel, selectedTab: ReportTab) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Milli-\(selectedTab.title)-Report.pdf")

        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let data = renderer.pdfData { context in
            context.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.darkGray
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.black
            ]

            NSString(string: "MILLI — \(selectedTab.title) Report")
                .draw(at: CGPoint(x: 42, y: 42), withAttributes: titleAttributes)
            NSString(string: "Money, Made Intelligent. • \(report.periodLabel)")
                .draw(at: CGPoint(x: 42, y: 76), withAttributes: subtitleAttributes)

            let lines = pdfLines(report: report, selectedTab: selectedTab)
            var y: CGFloat = 112
            for line in lines {
                NSString(string: line).draw(at: CGPoint(x: 42, y: y), withAttributes: bodyAttributes)
                y += 21
                if y > 740 {
                    context.beginPage()
                    y = 42
                }
            }
        }

        try data.write(to: url, options: .atomic)
        return url
    }

    private static func pdfLines(report: ReportDataModel, selectedTab: ReportTab) -> [String] {
        switch selectedTab {
        case .overview:
            let summary = [
                "Gross income: \(currency(report.grossIncome))",
                "Total deductions: \(currency(report.totalDeductions))",
                "Business miles: \(report.businessMiles.formatted(.number.precision(.fractionLength(0))))",
                "Mileage deduction: \(currency(report.mileageDeduction))",
                "Estimated tax savings: \(currency(report.estimatedTaxSavings))",
                "Tax reserved: \(currency(report.totalTaxReserved))",
                "",
                "Monthly cash flow"
            ]
            let months = report.months.map {
                "\($0.month): payouts \(currency($0.payoutIncome)) • cash \(currency($0.cashIncome)) • expenses \(currency($0.expenses)) • tax \(currency($0.taxReserved))"
            }
            return summary + months

        case .deductions:
            return report.categories.map {
                "\($0.name): \(currency($0.amount)) (\($0.share.formatted(.percent.precision(.fractionLength(1)))))"
            }
        case .trips:
            return report.trips.map {
                "\($0.platform) • \($0.dateLabel) • \($0.miles.formatted(.number.precision(.fractionLength(1)))) mi • \(currency($0.deduction))"
            }
        }
    }

    private static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"" + escaped + "\""
        }
        return value
    }
}
