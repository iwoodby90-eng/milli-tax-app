import SwiftUI

struct ExpensesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ExpenseTab = .expenses
    @State private var showAddExpense = false
    
    enum ExpenseTab: String, CaseIterable {
        case expenses = "Expenses"
        case receipts = "Receipts"
    }
    
    private let mockExpenses: [(icon: String, category: String, name: String, date: String, amount: Double)] = [
        ("fuelpump.fill", "Fuel", "Shell Gas Station", "Aug 8, 2026", 58.42),
        ("wrench.fill", "Car Maintenance", "Oil Change — Valvoline", "Aug 5, 2026", 89.99),
        ("parkingsign.circle.fill", "Tolls & Parking", "I-94 Toll", "Aug 4, 2026", 4.50),
        ("drop.fill", "Car Wash", "Motor City Car Wash", "Aug 2, 2026", 18.00),
        ("fuelpump.fill", "Fuel", "Marathon Gas", "Jul 30, 2026", 62.18),
        ("shippingbox.fill", "Supplies", "Phone Mount — Amazon", "Jul 28, 2026", 24.99),
        ("shield.fill", "Insurance", "Progressive — Monthly", "Jul 25, 2026", 142.00),
        ("wrench.fill", "Car Maintenance", "Tire Rotation", "Jul 22, 2026", 49.99),
        ("fuelpump.fill", "Fuel", "BP Gas Station", "Jul 20, 2026", 55.30),
        ("parkingsign.circle.fill", "Tolls & Parking", "Airport Parking", "Jul 18, 2026", 12.00),
    ]
    
    private var totalDeductions: Double {
        mockExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Expenses & Deductions", showBack: true, onBack: { dismiss() })
                
                // Tab Picker
                HStack(spacing: 0) {
                    ForEach(ExpenseTab.allCases, id: \.self) { tab in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                            VStack(spacing: 6) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedTab == tab ? .milliCyan : .milliTextSecondary)
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? Color.milliCyan : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                
                ScrollView(.vertical, showsIndicators: false) {
                    if selectedTab == .expenses {
                        expensesContent
                    } else {
                        receiptsContent
                    }
                }
            }
            
            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddExpense = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.milliCyan)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.milliCyan.opacity(0.4), radius: 12, x: 0, y: 4)
                            
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
        .navigationBarHidden(true)
        .alert("Add Expense", isPresented: $showAddExpense) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Expense entry form coming soon.")
        }
    }
    
    private var expensesContent: some View {
        VStack(spacing: 16) {
            // Total Deductions Header
            MilliCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOTAL DEDUCTIONS")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.5)
                        .foregroundColor(.milliTextSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("$\(String(format: "%.2f", totalDeductions))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("+12.4%")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.milliSuccess)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.milliSuccess.opacity(0.1))
                        .cornerRadius(6)
                        
                        Spacer()
                    }
                    
                    Text("vs. last month")
                        .font(.system(size: 12))
                        .foregroundColor(.milliTextTertiary)
                }
            }
            
            // Recent Expenses
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT EXPENSES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundColor(.milliTextSecondary)
                    .padding(.leading, 4)
                
                ForEach(Array(mockExpenses.enumerated()), id: \.offset) { _, expense in
                    MilliCard {
                        HStack(spacing: 12) {
                            Image(systemName: expense.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.milliCyan)
                                .frame(width: 36, height: 36)
                                .background(Color.milliCyan.opacity(0.1))
                                .cornerRadius(10)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(expense.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Text("\(expense.category) • \(expense.date)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.milliTextSecondary)
                            }
                            
                            Spacer()
                            
                            Text("-$\(String(format: "%.2f", expense.amount))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.milliSuccess)
                        }
                    }
                }
                
                Button(action: {}) {
                    Text("View All Expenses")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.milliCyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.milliCyan.opacity(0.08))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.milliCyan.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 100)
    }
    
    private var receiptsContent: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)
            
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 48, weight: .thin))
                .foregroundColor(.milliTextTertiary)
            
            VStack(spacing: 6) {
                Text("No receipts yet.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.milliTextSecondary)
                Text("Tap + to add one.")
                    .font(.system(size: 14))
                    .foregroundColor(.milliTextTertiary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 100)
    }
}
