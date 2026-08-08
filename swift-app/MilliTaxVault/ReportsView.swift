//
//  ReportsView.swift
//  MilliTaxVault
//
//  Tax reports dashboard with stat cards, income chart, and deductions list
//

import SwiftUI
import Charts

struct ReportsView: View {
    @State private var selectedYear = "2024"

    private let statCards: [StatCard] = [
        StatCard(title: "Total Income", value: "$127,450", color: MilliColors.green, icon: "chart.line.uptrend.xyaxis"),
        StatCard(title: "Total Deductions", value: "$31,240", color: MilliColors.accent, icon: "arrow.down.circle"),
        StatCard(title: "Estimated Tax Liability", value: "$24,890", color: Color(hex: "F59E0B"), icon: "exclamationmark.triangle"),
        StatCard(title: "Potential Refund", value: "$4,620", color: Color(hex: "A855F7"), icon: "dollarsign.circle")
    ]

    private let monthlyData: [MonthlyFinance] = [
        MonthlyFinance(month: "Jan", income: 9840, expenses: 4200),
        MonthlyFinance(month: "Feb", income: 11200, expenses: 5100),
        MonthlyFinance(month: "Mar", income: 10450, expenses: 4800),
        MonthlyFinance(month: "Apr", income: 12300, expenses: 6200),
        MonthlyFinance(month: "May", income: 9876, expenses: 4500),
        MonthlyFinance(month: "Jun", income: 11543, expenses: 5800),
        MonthlyFinance(month: "Jul", income: 10987, expenses: 5100),
        MonthlyFinance(month: "Aug", income: 11254, expenses: 5400)
    ]

    private let topDeductions: [DeductionEntry] = [
        DeductionEntry(name: "Business Mileage", amount: "$15,674", percentage: "12.3%"),
        DeductionEntry(name: "Home Office", amount: "$8,400", percentage: "6.6%"),
        DeductionEntry(name: "Business Meals", amount: "$3,240", percentage: "2.5%"),
        DeductionEntry(name: "Software & Tools", amount: "$2,890", percentage: "2.3%"),
        DeductionEntry(name: "Professional Dev", amount: "$1,036", percentage: "0.8%")
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                statGrid
                monthlyIncomeChart
                topDeductionsSection
                actionButtons
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .background(MilliColors.background)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Tax Reports")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            yearSelector
        }
    }

    private var yearSelector: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundColor(MilliColors.accent)
            Text(selectedYear)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(MilliColors.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MilliColors.card)
        .cornerRadius(8)
    }

    // MARK: - Stat Grid

    private var statGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(statCards) { card in
                statCardView(card: card)
            }
        }
    }

    private func statCardView(card: StatCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: card.icon)
                .font(.system(size: 20))
                .foregroundColor(card.color)
                .frame(width: 36, height: 36)
                .background(card.color.opacity(0.15))
                .cornerRadius(8)

            Text(card.title)
                .font(.system(size: 12))
                .foregroundColor(MilliColors.muted)

            Text(card.value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .milliCard()
    }

    // MARK: - Monthly Income Chart

    private var monthlyIncomeChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Monthly Income & Expenses")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Chart {
                ForEach(monthlyData) { item in
                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.income)
                    )
                    .foregroundStyle(MilliColors.green)
                    .cornerRadius(4)
                    .position(by: .value("Type", "Income"))

                    BarMark(
                        x: .value("Month", item.month),
                        y: .value("Amount", item.expenses)
                    )
                    .foregroundStyle(MilliColors.accent.opacity(0.7))
                    .cornerRadius(4)
                    .position(by: .value("Type", "Expenses"))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .foregroundStyle(MilliColors.muted)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.05))
                    AxisValueLabel()
                        .foregroundStyle(MilliColors.muted)
                }
            }
            .chartLegend(position: .bottom, alignment: .leading) {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle().fill(MilliColors.green).frame(width: 8, height: 8)
                        Text("Income").font(.caption).foregroundColor(MilliColors.muted)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(MilliColors.accent.opacity(0.7)).frame(width: 8, height: 8)
                        Text("Expenses").font(.caption).foregroundColor(MilliColors.muted)
                    }
                }
            }
            .frame(height: 180)
        }
        .padding(16)
        .milliCard()
    }

    // MARK: - Top Deductions

    private var topDeductionsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Top Deductions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(topDeductions) { deduction in
                    deductionRow(deduction: deduction)
                }
            }
        }
        .padding(16)
        .milliCard()
    }

    private func deductionRow(deduction: DeductionEntry) -> some View {
        HStack {
            Text(deduction.name)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
            Text(deduction.amount)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Text(deduction.percentage)
                .font(.system(size: 12))
                .foregroundColor(MilliColors.muted)
                .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {}) {
                Text("Generate Report")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(MilliColors.accent)
                    .cornerRadius(12)
            }

            Button(action: {}) {
                Text("Export to PDF")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MilliColors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.clear)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(MilliColors.accent, lineWidth: 1.5)
                    )
            }
        }
    }
}

// MARK: - Models

struct StatCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let color: Color
    let icon: String
}

struct MonthlyFinance: Identifiable {
    let id = UUID()
    let month: String
    let income: Double
    let expenses: Double
}

struct DeductionEntry: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    let percentage: String
}

// MARK: - Preview

#Preview {
    ReportsView()
}
