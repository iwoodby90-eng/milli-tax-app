//
//  ExpensesView.swift
//  MilliTaxVault
//
//  Full expense tracker with category breakdown and recent transactions
//

import SwiftUI
import Charts

struct ExpensesView: View {
    @State private var selectedMonth = "August 2024"

    private let categories: [ExpenseCategory] = [
        ExpenseCategory(name: "Office Supplies", amount: 1247, color: MilliColors.accent),
        ExpenseCategory(name: "Travel", amount: 892, color: Color(hex: "3B82F6")),
        ExpenseCategory(name: "Software", amount: 637, color: Color(hex: "A855F7")),
        ExpenseCategory(name: "Meals", amount: 428, color: Color(hex: "F59E0B"))
    ]

    private let recentExpenses: [ExpenseEntry] = [
        ExpenseEntry(name: "Adobe Creative Suite", date: "Aug 15", category: "Software", amount: 54.99, icon: "app.fill", iconColor: Color(hex: "A855F7")),
        ExpenseEntry(name: "Client Lunch", date: "Aug 14", category: "Meals", amount: 127.43, icon: "fork.knife", iconColor: Color(hex: "F59E0B")),
        ExpenseEntry(name: "Uber to Airport", date: "Aug 13", category: "Travel", amount: 47.21, icon: "car.fill", iconColor: Color(hex: "3B82F6")),
        ExpenseEntry(name: "Office Desk", date: "Aug 12", category: "Office", amount: 289.00, icon: "desktopcomputer", iconColor: MilliColors.accent),
        ExpenseEntry(name: "Zoom Pro", date: "Aug 11", category: "Software", amount: 15.99, icon: "video.fill", iconColor: Color(hex: "A855F7")),
        ExpenseEntry(name: "Hotel - Chicago", date: "Aug 10", category: "Travel", amount: 312.00, icon: "building.2.fill", iconColor: Color(hex: "3B82F6"))
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                heroSpendCard
                categoryBreakdown
                recentExpensesSection
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
            Text("Expenses")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            monthSelector
        }
    }

    private var monthSelector: some View {
        HStack(spacing: 12) {
            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MilliColors.muted)
            Text(selectedMonth)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(MilliColors.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MilliColors.card)
        .cornerRadius(8)
    }

    // MARK: - Hero Spend Card

    private var heroSpendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Spent")
                .font(.caption)
                .foregroundColor(MilliColors.muted)

            Text("$4,827.50")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [MilliColors.accent, Color(hex: "3B82F6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * 0.80, height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("$1,172.50 remaining")
                        .font(.caption)
                        .foregroundColor(MilliColors.muted)
                    Spacer()
                    Text("Budget: $6,000")
                        .font(.caption)
                        .foregroundColor(MilliColors.muted)
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [MilliColors.card, Color(hex: "1A1A2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(spacing: 16) {
            categoryChart
            categoryLegend
        }
        .padding(16)
        .milliCard()
    }

    private var categoryChart: some View {
        Chart(categories) { category in
            SectorMark(
                angle: .value("Amount", category.amount),
                innerRadius: .ratio(0.6),
                angularInset: 2
            )
            .foregroundStyle(category.color)
            .cornerRadius(4)
        }
        .frame(height: 180)
    }

    private var categoryLegend: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(categories) { category in
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(category.color)
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(category.name)
                            .font(.system(size: 11))
                            .foregroundColor(MilliColors.muted)
                        Text("$\(category.amount)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Recent Expenses

    private var recentExpensesSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Recent Expenses")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("See All")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(MilliColors.accent)
            }

            VStack(spacing: 10) {
                ForEach(recentExpenses) { expense in
                    expenseRow(expense: expense)
                }
            }
        }
    }

    private func expenseRow(expense: ExpenseEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: expense.icon)
                .font(.system(size: 16))
                .foregroundColor(expense.iconColor)
                .frame(width: 40, height: 40)
                .background(expense.iconColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text("\(expense.date) \u{00B7} \(expense.category)")
                    .font(.system(size: 12))
                    .foregroundColor(MilliColors.muted)
            }

            Spacer()

            Text("-$\(expense.amount, specifier: "%.2f")")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(MilliColors.red)
        }
        .padding(12)
        .milliCard()
    }
}

// MARK: - Models

struct ExpenseCategory: Identifiable {
    let id = UUID()
    let name: String
    let amount: Int
    let color: Color
}

struct ExpenseEntry: Identifiable {
    let id = UUID()
    let name: String
    let date: String
    let category: String
    let amount: Double
    let icon: String
    let iconColor: Color
}

// MARK: - Preview

#Preview {
    ExpensesView()
}
