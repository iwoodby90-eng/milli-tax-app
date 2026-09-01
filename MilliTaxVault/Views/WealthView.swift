import SwiftUI

// MARK: - SavingsView
// Goal-based savings planning kept distinct from Milli Cents™ and Milli Tax Vault™.
// The screen tracks user-defined savings goals and monthly targets; it does not
// imply a live deposit account until a banking partner is connected.

struct SavingsView: View {
    var onBack: () -> Void = {}

    @State private var goals: [SavingsGoal] = SavingsGoal.seeded
    @State private var showAddGoal = false

    private var totalSaved: Double {
        goals.reduce(0) { $0 + $1.saved }
    }

    private var totalTarget: Double {
        goals.reduce(0) { $0 + $1.target }
    }

    private var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(max(totalSaved / totalTarget, 0), 1)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                savingsHero
                goalsSection
                addGoalButton
                disclosure
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showAddGoal) {
            AddSavingsGoalSheet { goal in
                goals.append(goal)
            }
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

            Text("Savings")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)

            Spacer()

            Image(systemName: "target")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 34, height: 34)
        }
    }

    private var savingsHero: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text("SAVED TOWARD GOALS")
                    .sectionHeaderStyle()
                Text(totalSaved.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(MilliFont.heroNumber)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text("of \(totalTarget.formatted(.currency(code: "USD").precision(.fractionLength(0)))) total targets")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            ZStack {
                Circle().stroke(Color.white.opacity(0.07), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: overallProgress)
                    .stroke(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(overallProgress.formatted(.percent.precision(.fractionLength(0))))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            .frame(width: 76, height: 76)
        }
        .milliCard(padding: 14)
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SAVINGS GOALS")
                    .sectionHeaderStyle()
                Spacer()
                Text("\(goals.count) active")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            ForEach(goals) { goal in
                goalCard(goal)
            }
        }
    }

    private func goalCard(_ goal: SavingsGoal) -> some View {
        let progress = goal.target > 0 ? min(max(goal.saved / goal.target, 0), 1) : 0

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                Image(systemName: goal.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(goal.color)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(goal.color.opacity(0.09)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text("Target \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer()

                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(goal.color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(goal.color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)

            HStack {
                Text(goal.saved.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("saved")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                Spacer()
                Text("\(goal.monthlyTarget.formatted(.currency(code: "USD").precision(.fractionLength(0)))) / mo")
                    .font(MilliFont.caption)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textSecondary)
            }
        }
        .milliCard(padding: 12)
    }

    private var addGoalButton: some View {
        Button {
            showAddGoal = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add Savings Goal")
            }
            .font(MilliFont.headlineSmall)
            .foregroundStyle(MilliColors.cyanGlow)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.32), lineWidth: 0.8)
                    }
            )
        }
        .buttonStyle(.plain)
    }

    private var disclosure: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(MilliColors.textTertiary)
                .padding(.top, 1)
            Text("Savings goals in this build are planning targets. Milli does not represent these goals as live deposit accounts until a production banking connection is configured.")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .milliCard(padding: 11)
    }
}

private struct AddSavingsGoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (SavingsGoal) -> Void

    @State private var name = ""
    @State private var targetText = ""
    @State private var monthlyText = ""
    @State private var targetDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var goalType: SavingsGoalType = .emergency

    private var target: Double? {
        parseCurrency(targetText)
    }

    private var monthly: Double? {
        parseCurrency(monthlyText)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && target != nil && monthly != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        fieldSection("GOAL NAME") {
                            TextField("Emergency fund, home, vacation...", text: $name)
                                .font(MilliFont.bodyMedium)
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(fieldBackground)
                        }

                        fieldSection("GOAL TYPE") {
                            Menu {
                                ForEach(SavingsGoalType.allCases) { type in
                                    Button {
                                        goalType = type
                                    } label: {
                                        Label(type.title, systemImage: type.icon)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: goalType.icon)
                                        .foregroundStyle(goalType.color)
                                    Text(goalType.title)
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

                        currencyField(title: "TARGET AMOUNT", text: $targetText)
                        currencyField(title: "MONTHLY TARGET", text: $monthlyText)

                        fieldSection("TARGET DATE") {
                            DatePicker("Target date", selection: $targetDate, in: Date()..., displayedComponents: .date)
                                .labelsHidden()
                                .tint(MilliColors.cyanGlow)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .frame(height: 46)
                                .background(fieldBackground)
                        }

                        Button {
                            guard let target, let monthly else { return }
                            onSave(
                                SavingsGoal(
                                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                    saved: 0,
                                    target: target,
                                    monthlyTarget: monthly,
                                    targetDate: targetDate,
                                    icon: goalType.icon,
                                    color: goalType.color
                                )
                            )
                            dismiss()
                        } label: {
                            Text("Create Goal")
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
            .navigationTitle("New Savings Goal")
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

    private func currencyField(title: String, text: Binding<String>) -> some View {
        fieldSection(title) {
            HStack {
                Text("$")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textSecondary)
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .font(MilliFont.numericMedium)
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(fieldBackground)
        }
    }

    private func fieldSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
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

private enum SavingsGoalType: String, CaseIterable, Identifiable {
    case emergency
    case home
    case travel
    case vehicle
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emergency: return "Emergency Reserve"
        case .home: return "Home"
        case .travel: return "Travel"
        case .vehicle: return "Vehicle"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .emergency: return "shield.fill"
        case .home: return "house.fill"
        case .travel: return "airplane"
        case .vehicle: return "car.fill"
        case .custom: return "target"
        }
    }

    var color: Color {
        switch self {
        case .emergency: return MilliColors.positive
        case .home: return MilliColors.cyanGlow
        case .travel: return MilliColors.deepCyan
        case .vehicle: return MilliColors.warning
        case .custom: return MilliColors.silver
        }
    }
}

private struct SavingsGoal: Identifiable {
    let id = UUID()
    let name: String
    let saved: Double
    let target: Double
    let monthlyTarget: Double
    let targetDate: Date
    let icon: String
    let color: Color

    static var seeded: [SavingsGoal] {
        let calendar = Calendar.current
        let now = Date()
        func date(months: Int) -> Date {
            calendar.date(byAdding: .month, value: months, to: now) ?? now
        }

        return [
            SavingsGoal(name: "Emergency Reserve", saved: 12_800, target: 18_000, monthlyTarget: 600, targetDate: date(months: 9), icon: "shield.fill", color: MilliColors.positive),
            SavingsGoal(name: "Home Fund", saved: 18_765, target: 50_000, monthlyTarget: 1_250, targetDate: date(months: 24), icon: "house.fill", color: MilliColors.cyanGlow),
            SavingsGoal(name: "Vehicle Upgrade", saved: 4_200, target: 18_000, monthlyTarget: 450, targetDate: date(months: 30), icon: "car.fill", color: MilliColors.warning)
        ]
    }
}

// Legacy compatibility wrapper while the old segmented wealth hub is retired.
struct WealthView: View {
    var body: some View {
        SavingsView()
    }
}

#Preview {
    SavingsView()
        .preferredColorScheme(.dark)
}
