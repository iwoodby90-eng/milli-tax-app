import Combine
import SwiftUI

@MainActor
final class TreeOfLifeViewModel: ObservableObject {
    // NOTE: placeholder data — swap to APIService when the endpoint exists.
    @Published var goals: [LifeGoal] = [
        LifeGoal(title: "Buy a home", symbol: "house.fill", target: 40_000, saved: 12_500, targetDate: nil, monthlyAllocation: 300, vaultLinked: true),
        LifeGoal(title: "New car", symbol: "car.fill", target: 18_000, saved: 6_200, targetDate: nil, monthlyAllocation: 150, vaultLinked: false),
        LifeGoal(title: "Wedding", symbol: "heart.fill", target: 25_000, saved: 3_000, targetDate: nil, monthlyAllocation: 200, vaultLinked: false),
        LifeGoal(title: "Baby", symbol: "figure.and.child.holdinghands", target: 15_000, saved: 1_000, targetDate: nil, monthlyAllocation: 100, vaultLinked: false),
        LifeGoal(title: "Retire", symbol: "sailboat.fill", target: 1_000_000, saved: 42_500, targetDate: nil, monthlyAllocation: 400, vaultLinked: true)
    ]
    func update(_ goal: LifeGoal) {
        if let i = goals.firstIndex(where: { $0.id == goal.id }) { goals[i] = goal }
    }
}

struct TreeOfLifeView: View {
    @StateObject private var vm = TreeOfLifeViewModel()
    @State private var selected: LifeGoal?
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Tree of Life").font(.title2.weight(.bold)).foregroundStyle(MilliPalette.textPrimary)
                    Text("Grow toward what matters. Link goals to your Tax Vault auto-save.")
                        .font(.footnote).foregroundStyle(MilliPalette.textSecondary).multilineTextAlignment(.center)
                }
                Capsule()
                    .fill(LinearGradient(colors: [MilliPalette.accent.opacity(0.0), MilliPalette.accent.opacity(0.5)], startPoint: .bottom, endPoint: .top))
                    .frame(width: 6, height: 120).blur(radius: 2)
                    .shadow(color: MilliPalette.accent.opacity(0.6), radius: 12)
                VStack(spacing: 14) {
                    ForEach(vm.goals) { goal in
                        Button { selected = goal } label: { nodeRow(goal) }.buttonStyle(.plain)
                    }
                }
            }.padding()
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .sheet(item: $selected) { goal in
            GoalDetailView(goal: goal) { updated in vm.update(updated) }
        }
    }
    private func nodeRow(_ goal: LifeGoal) -> some View {
        DKCard {
            HStack(spacing: 14) {
                ZStack {
                    MilliProgressRing(progress: goal.progress, lineWidth: 6).frame(width: 52, height: 52)
                    Image(systemName: goal.symbol).foregroundStyle(MilliPalette.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(goal.title).font(.subheadline.weight(.semibold)).foregroundStyle(MilliPalette.textPrimary)
                        if goal.vaultLinked { Image(systemName: "arrow.triangle.branch").font(.caption2).foregroundStyle(MilliPalette.accent) }
                    }
                    Text(milliCurrency(goal.saved) + " of " + milliCurrency(goal.target)).font(.caption).foregroundStyle(MilliPalette.textSecondary)
                }
                Spacer()
                Text("\(Int(goal.progress * 100))%").font(.headline).foregroundStyle(MilliPalette.accent)
            }
        }
    }
}

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var goal: LifeGoal
    var onSave: (LifeGoal) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Image(systemName: goal.symbol).font(.title).foregroundStyle(MilliPalette.accent)
                        Text(goal.title).font(.title2.weight(.bold)).foregroundStyle(MilliPalette.textPrimary)
                    }
                    DKCard {
                        VStack(alignment: .leading, spacing: 12) {
                            labeled("Target amount", milliCurrency(goal.target))
                            Slider(value: $goal.target, in: 1000...1_000_000, step: 500).tint(MilliPalette.accent)
                            Divider().overlay(MilliPalette.cardBorder)
                            labeled("Monthly allocation", milliCurrency(goal.monthlyAllocation))
                            Slider(value: $goal.monthlyAllocation, in: 0...2000, step: 25).tint(MilliPalette.accent)
                            Divider().overlay(MilliPalette.cardBorder)
                            Toggle(isOn: $goal.vaultLinked) {
                                Text("Route a slice of Tax Vault auto-save here").font(.subheadline).foregroundStyle(MilliPalette.textPrimary)
                            }.tint(MilliPalette.accent)
                        }
                    }
                    DatePicker("Target date", selection: Binding(get: { goal.targetDate ?? Date() }, set: { goal.targetDate = $0 }), displayedComponents: .date)
                        .datePickerStyle(.compact).tint(MilliPalette.accent).foregroundStyle(MilliPalette.textPrimary)
                }.padding()
            }
            .background(MilliPalette.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Save") { onSave(goal); dismiss() }.tint(MilliPalette.accent) }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }
    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundStyle(MilliPalette.textSecondary)
            Spacer()
            Text(value).font(.headline).foregroundStyle(MilliPalette.accent)
        }
    }
}
