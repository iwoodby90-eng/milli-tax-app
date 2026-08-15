import SwiftUI
import Charts

// MARK: - ReportsView
// Dense deductible-expense reporting surface with native Swift Charts and export actions.

struct ReportsView: View {
    var onBack: () -> Void = {}
    @State private var selectedTab = ReportTab.deductions

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                tabs
                summary
                deductionsChart
                categoryList
                exportActions
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
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

            Button {} label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
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

    private var summary: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL DEDUCTIONS")
                    .sectionHeaderStyle()
                Text("$2,843.17")
                    .font(MilliFont.numericLarge)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("THIS YEAR")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Text("▲ 8.7%")
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.positive)
                Text("vs last year")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .milliCard(padding: 14)
    }

    private var deductionsChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("DEDUCTIONS BY MONTH")
                    .sectionHeaderStyle()
                Spacer()
                Text("28.4% deduction rate")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Chart(monthData) { point in
                BarMark(
                    x: .value("Month", point.month),
                    y: .value("Amount", point.amount)
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
        }
        .milliCard(padding: 14)
    }

    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOP DEDUCTION CATEGORIES")
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
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

                        Text(category.amount)
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)

                        Text(category.percent)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textSecondary)
                            .frame(width: 40, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)

                    if index < categories.count - 1 {
                        Divider()
                            .overlay(Color.white.opacity(0.05))
                            .padding(.leading, 48)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private var exportActions: some View {
        HStack(spacing: 8) {
            exportButton("Export PDF", icon: "doc.richtext")
            exportButton("Export CSV", icon: "tablecells")
            exportButton("Share", icon: "square.and.arrow.up")
        }
    }

    private func exportButton(_ title: String, icon: String) -> some View {
        Button {} label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(MilliFont.caption)
            }
            .foregroundStyle(MilliColors.cyanGlow)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
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

    private var monthData: [ReportMonth] {
        [
            .init(month: "Jan", amount: 410), .init(month: "Feb", amount: 575),
            .init(month: "Mar", amount: 720), .init(month: "Apr", amount: 940),
            .init(month: "May", amount: 650), .init(month: "Jun", amount: 610)
        ]
    }

    private var categories: [ReportCategory] {
        [
            .init(name: "Fuel", amount: "$1,286.45", percent: "45.2%", color: MilliColors.cyanGlow, icon: "fuelpump.fill"),
            .init(name: "Car Maintenance", amount: "$642.17", percent: "22.6%", color: MilliColors.deepCyan, icon: "wrench.and.screwdriver.fill"),
            .init(name: "Insurance", amount: "$389.45", percent: "13.7%", color: Color(hex: "7C8CFF"), icon: "shield.fill"),
            .init(name: "Tolls & Parking", amount: "$246.30", percent: "8.6%", color: MilliColors.warning, icon: "parkingsign.circle.fill"),
            .init(name: "Other", amount: "$278.80", percent: "9.9%", color: MilliColors.textSecondary, icon: "ellipsis.circle.fill")
        ]
    }
}

private enum ReportTab: CaseIterable {
    case overview, deductions, trips

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .deductions: return "Deductions"
        case .trips: return "Trips"
        }
    }
}

private struct ReportMonth: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

private struct ReportCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let percent: String
    let color: Color
    let icon: String
}
