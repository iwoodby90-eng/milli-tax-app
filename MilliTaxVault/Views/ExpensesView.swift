import SwiftUI

// MARK: - ExpensesView
// Premium native expense + receipt surface. All visible controls are functional;
// OCR/camera ingestion remains explicitly unavailable until its production service is connected.

struct ExpensesView: View {
    var onBack: () -> Void = {}

    @State private var selectedTab: ExpenseTab = .expenses
    @State private var expenses: [ExpenseItem] = ExpenseItem.seeded
    @State private var receipts: [ReceiptItem] = ReceiptItem.seeded
    @State private var showAddExpense = false
    @State private var showAddReceipt = false
    @State private var showNotifications = false

    private var totalDeductions: Double {
        expenses.filter(\.isDeductible).reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    header
                    segmentedControl
                    summaryCard

                    if selectedTab == .expenses {
                        expenseList
                    } else {
                        receiptList
                    }
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.top, 8)
                .padding(.bottom, MilliSpacing.bottomContentClearance + 48)
            }
            .background(MilliColors.background.ignoresSafeArea())

            addButton
        }
        .sheet(isPresented: $showAddExpense) {
            AddExpenseSheet { expense in
                expenses.insert(expense, at: 0)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddReceipt) {
            AddReceiptSheet { receipt in
                receipts.insert(receipt, at: 0)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotifications) {
            MilliDetailSheet(title: "Notifications")
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Button {
                    showNotifications = true
                } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.025)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notifications")
            }

            Text("Expenses")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)
        }
        .frame(height: 40)
    }

    private var segmentedControl: some View {
        HStack(spacing: 3) {
            ForEach(ExpenseTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.title)
                            .font(MilliFont.labelLarge)
                    }
                    .foregroundStyle(selectedTab == tab ? MilliColors.blackGlass : MilliColors.cyanGlow.opacity(0.82))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(
                        Capsule(style: .continuous)
                            .fill(selectedTab == tab ? MilliColors.cyanGlow : Color.clear)
                            .shadow(color: selectedTab == tab ? MilliColors.cyanGlow.opacity(0.22) : .clear, radius: 7)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            Capsule(style: .continuous)
                .fill(MilliColors.cardBackground)
                .overlay(Capsule().stroke(Color.white.opacity(0.05), lineWidth: 0.7))
        )
    }

    private var summaryCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL DEDUCTIONS")
                    .sectionHeaderStyle()
                // Seeded session data until expense sync is wired — labeled DEMO.
                ProvenanceTag(label: .demo)
                Text(totalDeductions.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericLarge)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("CAPTURE STATUS")
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                Text("\(receipts.filter(\.isLinked).count)/\(receipts.count) linked")
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.positive)
                Text("Receipts connected")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .milliCard(padding: 14)
    }

    private var expenseList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECENT EXPENSES")
                    .sectionHeaderStyle()
                Spacer()
                Text("\(expenses.count) items")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            VStack(spacing: 0) {
                ForEach(Array(expenses.enumerated()), id: \.element.id) { index, expense in
                    expenseRow(expense)
                    if index < expenses.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 50)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }

    private func expenseRow(_ expense: ExpenseItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: expense.category.icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(expense.category.color)
                .frame(width: 30, height: 30)
                .background(Circle().fill(expense.category.color.opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("\(expense.category.title) • \(expense.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(expense.amount.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                if expense.isDeductible {
                    Text("Deductible")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.positive)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var receiptList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("RECEIPT CAPTURE")
                    .sectionHeaderStyle()
                Spacer()
                Text("METADATA READY")
                    .font(MilliFont.caption)
                    .tracking(0.45)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            if receipts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("No receipts captured yet")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .milliCard()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                        receiptRow(receipt)
                        if index < receipts.count - 1 {
                            Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 50)
                        }
                    }
                }
                .background(MilliCardBackground(showGlow: true))
            }
        }
    }

    private func receiptRow(_ receipt: ReceiptItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: receipt.isLinked ? "doc.text.fill" : "doc.badge.plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(receipt.isLinked ? MilliColors.positive : MilliColors.warning)
                .frame(width: 30, height: 30)
                .background(Circle().fill((receipt.isLinked ? MilliColors.positive : MilliColors.warning).opacity(0.10)))

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.merchant)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(receipt.date.formatted(date: .abbreviated, time: .omitted))
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(receipt.amount.formatted(.currency(code: "USD")))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text(receipt.isLinked ? "Linked" : "Needs review")
                    .font(MilliFont.caption)
                    .foregroundStyle(receipt.isLinked ? MilliColors.positive : MilliColors.warning)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
    }

    private var addButton: some View {
        Button {
            if selectedTab == .expenses {
                showAddExpense = true
            } else {
                showAddReceipt = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(MilliColors.blackGlass)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 10)
                )
        }
        .buttonStyle(.plain)
        .padding(.trailing, MilliSpacing.screenHorizontal)
        .padding(.bottom, MilliSpacing.bottomNavHeight + 18)
        .accessibilityLabel(selectedTab == .expenses ? "Add expense" : "Add receipt")
    }
}

// MARK: - Add Expense

private struct AddExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ExpenseItem) -> Void

    @State private var merchant = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .fuel
    @State private var date = Date()
    @State private var deductible = true

    private var amount: Double? {
        parseCurrency(amountText)
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        inputSection("MERCHANT") {
                            TextField("Gas station, repair shop, store...", text: $merchant)
                                .font(MilliFont.bodyMedium)
                                .foregroundStyle(MilliColors.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(fieldBackground)
                        }

                        inputSection("AMOUNT") {
                            HStack {
                                Text("$")
                                    .font(MilliFont.headlineSmall)
                                    .foregroundStyle(MilliColors.textSecondary)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .font(MilliFont.numericMedium)
                                    .monospacedDigit()
                                    .foregroundStyle(MilliColors.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 46)
                            .background(fieldBackground)
                        }

                        inputSection("CATEGORY") {
                            Menu {
                                ForEach(ExpenseCategory.allCases) { item in
                                    Button {
                                        category = item
                                    } label: {
                                        Label(item.title, systemImage: item.icon)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundStyle(category.color)
                                    Text(category.title)
                                        .font(MilliFont.bodyMedium)
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(MilliColors.textTertiary)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(fieldBackground)
                            }
                        }

                        inputSection("DATE") {
                            DatePicker("Expense date", selection: $date, in: ...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .tint(MilliColors.cyanGlow)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(fieldBackground)
                        }

                        Toggle(isOn: $deductible) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Business Deduction")
                                    .font(MilliFont.bodyMedium)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text("Include this expense in deductible reporting")
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.textSecondary)
                            }
                        }
                        .tint(MilliColors.cyanGlow)
                        .milliCard(padding: 12)

                        Button {
                            guard let amount else { return }
                            onSave(
                                ExpenseItem(
                                    merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                                    category: category,
                                    date: date,
                                    amount: amount,
                                    isDeductible: deductible
                                )
                            )
                            dismiss()
                        } label: {
                            Text("Save Expense")
                                .font(MilliFont.headlineSmall)
                                .foregroundStyle(MilliColors.blackGlass)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(canSave ? MilliColors.cyanGlow : MilliColors.textTertiary)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func inputSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).sectionHeaderStyle()
            content()
        }
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(MilliColors.graphiteSurface)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
            }
    }

    private func parseCurrency(_ raw: String) -> Double? {
        let cleaned = raw.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }
}

// MARK: - Add Receipt

private struct AddReceiptSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ReceiptItem) -> Void

    @State private var merchant = ""
    @State private var amountText = ""
    @State private var date = Date()

    private var amount: Double? {
        let cleaned = amountText.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")
        guard let value = Double(cleaned), value > 0 else { return nil }
        return value
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && amount != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(MilliColors.cyanGlow)

                    Text("Receipt Capture")
                        .font(MilliFont.screenTitle)
                        .foregroundStyle(MilliColors.textPrimary)

                    Text("Camera/OCR ingestion is not connected in this build yet. You can add the receipt metadata now without pretending an OCR scan occurred.")
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textSecondary)
                        .multilineTextAlignment(.center)

                    TextField("Merchant", text: $merchant)
                        .font(MilliFont.bodyMedium)
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(fieldBackground)

                    HStack {
                        Text("$")
                            .foregroundStyle(MilliColors.textSecondary)
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(MilliFont.numericSmall)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 46)
                    .background(fieldBackground)

                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                        .tint(MilliColors.cyanGlow)
                        .font(MilliFont.bodyMedium)
                        .foregroundStyle(MilliColors.textPrimary)
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(fieldBackground)

                    Button {
                        guard let amount else { return }
                        onSave(
                            ReceiptItem(
                                merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
                                date: date,
                                amount: amount,
                                isLinked: false
                            )
                        )
                        dismiss()
                    } label: {
                        Text("Add Receipt Metadata")
                            .font(MilliFont.headlineSmall)
                            .foregroundStyle(MilliColors.blackGlass)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(canSave ? MilliColors.cyanGlow : MilliColors.textTertiary)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .padding(24)
            }
            .navigationTitle("Add Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(MilliColors.graphiteSurface)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
            }
    }
}

private enum ExpenseTab: CaseIterable {
    case expenses
    case receipts

    var title: String {
        switch self {
        case .expenses: return "Expenses"
        case .receipts: return "Receipts"
        }
    }

    var icon: String {
        switch self {
        case .expenses: return "creditcard.fill"
        case .receipts: return "doc.text.fill"
        }
    }
}

private enum ExpenseCategory: String, CaseIterable, Identifiable {
    case fuel
    case maintenance
    case parking
    case supplies
    case insurance
    case professional
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fuel: return "Fuel"
        case .maintenance: return "Car Maintenance"
        case .parking: return "Tolls & Parking"
        case .supplies: return "Supplies"
        case .insurance: return "Insurance"
        case .professional: return "Professional Services"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .parking: return "parkingsign.circle.fill"
        case .supplies: return "shippingbox.fill"
        case .insurance: return "shield.fill"
        case .professional: return "briefcase.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .fuel: return MilliColors.warning
        case .maintenance: return Color(hex: "4285F4")
        case .parking: return MilliColors.deepCyan
        case .supplies: return MilliColors.positive
        case .insurance: return MilliColors.negative
        case .professional: return MilliColors.cyanGlow
        case .other: return MilliColors.textSecondary
        }
    }
}

private struct ExpenseItem: Identifiable {
    let id = UUID()
    let merchant: String
    let category: ExpenseCategory
    let date: Date
    let amount: Double
    let isDeductible: Bool

    static var seeded: [ExpenseItem] {
        let calendar = Calendar.current
        let now = Date()
        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        return [
            ExpenseItem(merchant: "Fuel Stop", category: .fuel, date: date(daysAgo: 0), amount: 68.42, isDeductible: true),
            ExpenseItem(merchant: "Vehicle Service", category: .maintenance, date: date(daysAgo: 1), amount: 89.75, isDeductible: true),
            ExpenseItem(merchant: "City Parking", category: .parking, date: date(daysAgo: 3), amount: 24.60, isDeductible: true),
            ExpenseItem(merchant: "Delivery Supplies", category: .supplies, date: date(daysAgo: 5), amount: 12.35, isDeductible: true),
            ExpenseItem(merchant: "Auto Insurance", category: .insurance, date: date(daysAgo: 7), amount: 39.45, isDeductible: true)
        ]
    }
}

private struct ReceiptItem: Identifiable {
    let id = UUID()
    let merchant: String
    let date: Date
    let amount: Double
    let isLinked: Bool

    static var seeded: [ReceiptItem] {
        let calendar = Calendar.current
        let now = Date()
        func date(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        return [
            ReceiptItem(merchant: "Fuel Stop", date: date(daysAgo: 0), amount: 68.42, isLinked: true),
            ReceiptItem(merchant: "Vehicle Service", date: date(daysAgo: 1), amount: 89.75, isLinked: true),
            ReceiptItem(merchant: "City Parking", date: date(daysAgo: 3), amount: 24.60, isLinked: false)
        ]
    }
}

#Preview {
    ExpensesView()
        .preferredColorScheme(.dark)
}
