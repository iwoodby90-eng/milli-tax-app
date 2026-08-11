import SwiftUI
import Combine
import Charts

@MainActor
final class RetirementViewModel: ObservableObject {
    // NOTE: placeholder data — swap to APIService when the endpoint exists.
    @Published var plan = RetirementPlan(currentBalance: 42_500, monthlyContribution: 400,
                                         currentAge: 32, retirementAge: 65,
                                         annualReturn: 0.07, accountType: "Roth IRA")
    var projection: [RetirementPoint] { plan.projection() }
    var projectedBalance: Double { plan.projectedBalance }
    var onTrack: Bool { projectedBalance >= 1_000_000 }
}

struct RetirementView: View {
    @StateObject private var vm = RetirementViewModel()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                projectionCard
                contributionCard
                chipsRow
            }.padding()
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Retirement")
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Projected at 65").font(.subheadline).foregroundStyle(MilliPalette.textSecondary)
            Text(milliCurrency(vm.projectedBalance)).font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(MilliPalette.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: vm.onTrack ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                Text(vm.onTrack ? "On track" : "Behind target")
            }.font(.caption.weight(.semibold)).foregroundStyle(vm.onTrack ? MilliPalette.positive : MilliPalette.negative)
        }
    }
    private var projectionCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Growth to retirement").font(.headline).foregroundStyle(MilliPalette.textPrimary)
                Chart(vm.projection) { p in
                    AreaMark(x: .value("Age", p.age), y: .value("Balance", p.balance))
                        .foregroundStyle(LinearGradient(colors: [MilliPalette.accent.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Age", p.age), y: .value("Balance", p.balance))
                        .foregroundStyle(MilliPalette.accent).interpolationMethod(.catmullRom)
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
                .frame(height: 200)
            }
        }
    }
    private var contributionCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Monthly contribution").font(.subheadline).foregroundStyle(MilliPalette.textSecondary)
                    Spacer()
                    Text(milliCurrency(vm.plan.monthlyContribution)).font(.headline).foregroundStyle(MilliPalette.accent)
                }
                Slider(value: $vm.plan.monthlyContribution, in: 0...2000, step: 25).tint(MilliPalette.accent)
            }
        }
    }
    private var chipsRow: some View {
        HStack { chip(vm.plan.accountType); chip("7% est. return"); Spacer() }
    }
    private func chip(_ text: String) -> some View {
        Text(text).font(.caption.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(MilliPalette.accent.opacity(0.15))).foregroundStyle(MilliPalette.accent)
    }
}
