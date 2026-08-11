import SwiftUI

struct ExpensesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ExpenseTab = .expenses
    @State private var showAddExpense = false

    enum ExpenseTab: String, CaseIterable, Hashable {
        case expenses = "Expenses"
        case receipts = "Receipts"
    }

    private let mockExpenses: [(icon: String, category: String, name: String, date: String, amount: Double)] = [
        ("fuelpump.fill", "Fuel", "Shell Gas Station", "Aug 8, 2026", 58.42),
        ("wrench.fill", "Maintenance", "Oil Change — Valvoline", "Aug 5, 2026", 89.99),
        ("parkingsign.circle.fill", "Tolls", "I-94 Toll", "Aug 4, 2026", 4.50),
        ("drop.fill", "Car Wash", "Motor City Car Wash", "Aug 2, 2026", 18.00),
        ("fuelpump.fill", "Fuel", "Marathon Gas", "Jul 30, 2026", 62.18),
        ("shippingbox.fill", "Supplies", "Phone Mount — Amazon", "Jul 28, 2026", 24.99),
        ("shield.fill", "Insurance", "Progressive — Monthly", "Jul 25, 2026", 142.00),
        ("wrench.fill", "Maintenance", "Tire Rotation", "Jul 22, 2026", 49.99),
    ]

    private var totalDeductions: Double { mockExpenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    MilliSegmentedPicker(
                        options: ExpenseTab.allCases,
                        label: { $0.rawValue },
                        selection: $selectedTab
                    )

                    if selectedTab == .expenses {
                        expensesContent
                    } else {
                        receiptsContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 88)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddExpense = true }) {
                        ZStack {
                            Circle()
                                .fill(MilliPalette.accent)
                                .frame(width: 56, height: 56)
                                .shadow(color: MilliPalette.accent.opacity(0.4), radius: 12, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Expenses")
    }

    // MARK: - Expenses Content

    private var expensesContent: some View {
        VStack(spacing: 14) {
            // Hero
            DKCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Total Deductions")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                    Text(milliCurrency(totalDeductions, fraction: 2))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(MilliPalette.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                        Text("+12.4% vs last month")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(MilliPalette.positive)
                }
            }

            // List
            ForEach(Array(mockExpenses.enumerated()), id: \.offset) { _, expense in
                DKCard {
                    HStack(spacing: 12) {
                        Image(systemName: expense.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(MilliPalette.accent)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(MilliPalette.accent.opacity(0.1)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(MilliPalette.textPrimary)
                            Text("\(expense.category) \u{2022} \(expense.date)")
                                .font(.caption2)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                        Spacer()
                        Text("-\(milliCurrency(expense.amount, fraction: 2))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(MilliPalette.positive)
                    }
                }
            }
        }
    }

    // MARK: - Receipts Content

    private var receiptsContent: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(MilliPalette.textSecondary)
            Text("No receipts yet.")
                .font(.subheadline)
                .foregroundStyle(MilliPalette.textSecondary)
            Text("Tap + to add one.")
                .font(.caption)
                .foregroundStyle(MilliPalette.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
