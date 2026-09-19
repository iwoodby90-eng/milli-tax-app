import SwiftUI
import Charts
import UIKit

// MARK: - ReportsView
// Native reporting surface with genuinely different report tabs and working
// local PDF/CSV export. Exported documents contain only the data currently
// represented by the report model; production repositories can replace the seed model.

struct ReportsView: View {
    var onBack: () -> Void = {}

    @State private var selectedTab = ReportTab.deductions
    @State private var sharePayload: ReportSharePayload?

    @StateObject private var mileageLog = MileageLogStore()
    @ObservedObject private var expenseStore = ExpenseStore.shared

    private var report: ReportDataModel {
        ReportDataModel.live(
            expenses: expenseStore.expenses,
            trips: mileageLog.records,
            snapshot: MilliFinancialSnapshot.current()
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                tabs
                selectedContent
                exportActions
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background { MilliAmbientBackground() }
        .sheet(item: $sharePayload) { payload in
            ReportActivityView(items: [payload.url])
                .ignoresSafeArea()
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

            Text("Reports")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Button {
                exportPDFAndShare()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Share current report")
        }
    }

    private var tabs: some View {
        HStack(spacing: 2) {
            ForEach(ReportTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 7) {
                        Text(tab.title)
                            .font(MilliFont.labelLarge)
                            .foregroundStyle(selectedTab == tab ? MilliColors.cyanGlow : MilliColors.textSecondary)
                        Rectangle()
                            .fill(selectedTab == tab ? MilliColors.cyanGlow : Color.clear)
                            .frame(height: 1.5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
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
        VStack(spacing: 10) {
            HStack(spacing: MilliSpacing.gridGap) {
                overviewMetric("GROSS INCOME", currency(report.grossIncome), MilliColors.textPrimary)
                overviewMetric("DEDUCTIONS", currency(report.totalDeductions), MilliColors.cyanGlow)
            }

            HStack(spacing: MilliSpacing.gridGap) {
                overviewMetric("BUSINESS MILES", "\(Int(report.businessMiles).formatted()) mi", MilliColors.textPrimary)
                overviewMetric("EST. TAX SAVED", currency(report.estimatedTaxSavings), MilliColors.positive)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("MONTHLY ACTIVITY")
                        .sectionHeaderStyle()
                    Spacer()
                    Text(report.periodLabel)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Chart(report.months) { point in
                    LineMark(
                        x: .value("Month", point.month),
                        y: .value("Deductions", point.deductions)
                    )
                    .foregroundStyle(MilliColors.cyanGlow)
                    .lineStyle(StrokeStyle(lineWidth: 1.8))
                    .interpolationMethod(.catmullRom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.04))
                        AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                    }
                }
                .frame(height: 180)
                .overlay {
                    if report.months.isEmpty {
                        Text("Activity appears as expenses and trips are recorded")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                }
            }
            .milliCard(padding: 14)
        }
    }

    private func overviewMetric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .tracking(0.45)
                .foregroundStyle(MilliColors.textSecondary)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .milliCard(padding: 11)
    }

    // MARK: Deductions

    private var deductionsContent: some View {
        VStack(spacing: 10) {
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
            .milliCard(padding: 14)

            deductionsChart
            categoryList
        }
    }

    private var deductionsChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DEDUCTIONS BY MONTH")
                    .sectionHeaderStyle()
                Spacer()
                Text(report.periodLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Chart(report.months) { point in
                BarMark(
                    x: .value("Month", point.month),
                    y: .value("Amount", point.deductions)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(2)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.045))
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel().foregroundStyle(MilliColors.textTertiary)
                }
            }
            .frame(height: 170)
            .overlay {
                if report.months.isEmpty {
                    Text("No deductions recorded yet")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
        }
        .milliCard(padding: 14)
    }

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOP DEDUCTION CATEGORIES")
                .sectionHeaderStyle()

            if report.categories.isEmpty {
                Text("Log an expense and its category breakdown appears here.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(report.categories.enumerated()), id: \.element.id) { index, category in
                    HStack(spacing: 10) {
                        Image(systemName: category.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(category.color)
                            .frame(width: 26, height: 26)
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
                    .padding(.vertical, 9)

                    if index < report.categories.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.05))
                            .padding(.leading, 48)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    // MARK: Trips

    private var tripsContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: MilliSpacing.gridGap) {
                overviewMetric("BUSINESS MILES", "\(Int(report.businessMiles).formatted()) mi", MilliColors.textPrimary)
                overviewMetric("MILEAGE VALUE", currency(report.mileageDeduction), MilliColors.positive)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("RECENT BUSINESS TRIPS")
                    .sectionHeaderStyle()

                if report.trips.isEmpty {
                    Text("Track or log a drive and it appears here with its deduction.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }

                VStack(spacing: 0) {
                    ForEach(Array(report.trips.enumerated()), id: \.element.id) { index, trip in
                        HStack(spacing: 10) {
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MilliColors.cyanGlow)
                                .frame(width: 30, height: 30)
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
                        .padding(.vertical, 9)

                        if index < report.trips.count - 1 {
                            Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 48)
                        }
                    }
                }
                .background(MilliCardBackground(showGlow: true))
            }
        }
    }

    // MARK: Export

    private var exportActions: some View {
        HStack(spacing: 8) {
            exportButton("Export PDF", icon: "doc.richtext", action: exportPDFAndShare)
            exportButton("Export CSV", icon: "tablecells", action: exportCSVAndShare)
        }
    }

    private func exportButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(MilliFont.labelLarge)
            }
            .foregroundStyle(MilliColors.cyanGlow)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
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
    let income: Double
    let deductions: Double
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

    var periodLabel: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    /// Everything here comes from verified payouts, user-entered expenses and
    /// recorded trips. Nothing is estimated on the user's behalf.
    @MainActor
    static func live(
        expenses: [ExpenseItem],
        trips: [MileageTripRecord],
        snapshot: MilliFinancialSnapshot
    ) -> ReportDataModel {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: snapshot.referenceDate)
        let yearExpenses = expenses.filter {
            $0.isDeductible && calendar.component(.year, from: $0.date) == year
        }
        let yearTrips = trips.filter { calendar.component(.year, from: $0.startedAt) == year }

        let expenseTotal = yearExpenses.reduce(0) { $0 + $1.amount }
        let mileageDeduction = yearTrips.reduce(0) { $0 + $1.deductionAmount }
        let businessMiles = yearTrips.reduce(0) { $0 + $1.distanceMiles }
        let deductions = expenseTotal + mileageDeduction
        let grossIncome = snapshot.grossPayouts ?? 0
        let savings = (snapshot.effectiveRate).map { deductions * $0 } ?? 0

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        var monthlyExpenses: [Int: Double] = [:]
        for expense in yearExpenses {
            monthlyExpenses[calendar.component(.month, from: expense.date), default: 0] += expense.amount
        }
        let months: [ReportMonth] = monthlyExpenses.keys.sorted().compactMap { month in
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return nil }
            return ReportMonth(
                month: monthFormatter.string(from: date),
                income: 0,
                deductions: monthlyExpenses[month] ?? 0
            )
        }

        let palette: [Color] = [
            MilliColors.cyanGlow, MilliColors.deepCyan, MilliColors.silver,
            MilliColors.warning, MilliColors.textSecondary
        ]
        var byCategory: [ExpenseCategory: Double] = [:]
        for expense in yearExpenses {
            byCategory[expense.category, default: 0] += expense.amount
        }
        let categories: [ReportCategory] = byCategory
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { index, entry in
                ReportCategory(
                    name: entry.key.title,
                    amount: entry.value,
                    share: expenseTotal > 0 ? entry.value / expenseTotal : 0,
                    color: palette[index % palette.count],
                    icon: entry.key.icon
                )
            }

        let tripFormatter = DateFormatter()
        tripFormatter.dateFormat = "MMM d • h:mm a"
        let tripRows: [BusinessTrip] = yearTrips.prefix(12).map { trip in
            BusinessTrip(
                platform: trip.platform ?? trip.businessPurpose ?? "Business trip",
                dateLabel: tripFormatter.string(from: trip.startedAt),
                miles: trip.distanceMiles,
                deduction: trip.deductionAmount
            )
        }

        return ReportDataModel(
            grossIncome: grossIncome,
            totalDeductions: deductions,
            businessMiles: businessMiles,
            mileageDeduction: mileageDeduction,
            estimatedTaxSavings: savings,
            months: months,
            categories: categories,
            trips: tripRows
        )
    }
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
            csv = [
                "Metric,Value",
                "Gross Income,\(report.grossIncome)",
                "Total Deductions,\(report.totalDeductions)",
                "Business Miles,\(report.businessMiles)",
                "Mileage Deduction,\(report.mileageDeduction)",
                "Estimated Tax Savings,\(report.estimatedTaxSavings)"
            ].joined(separator: "\n")

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
            return [
                "Gross income: \(currency(report.grossIncome))",
                "Total deductions: \(currency(report.totalDeductions))",
                "Business miles: \(report.businessMiles.formatted(.number.precision(.fractionLength(0))))",
                "Mileage deduction: \(currency(report.mileageDeduction))",
                "Estimated tax savings: \(currency(report.estimatedTaxSavings))"
            ]
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
