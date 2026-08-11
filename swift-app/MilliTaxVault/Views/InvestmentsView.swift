import Combine
import SwiftUI
import Charts

@MainActor
final class InvestmentsViewModel: ObservableObject {
    // NOTE: placeholder data — swap to APIService when the endpoint exists.
    @Published var holdings: [Holding] = [
        Holding(ticker: "VTI",  name: "Vanguard Total Market", value: 6_240, dayChangePct: 0.8,  spark: [10,11,10.5,12,12.4,13],       assetClass: .etfs),
        Holding(ticker: "AAPL", name: "Apple Inc.",            value: 3_180, dayChangePct: -0.4, spark: [14,13.6,13.8,13.2,13.5,13.1], assetClass: .stocks),
        Holding(ticker: "BTC",  name: "Bitcoin",               value: 2_650, dayChangePct: 2.1,  spark: [8,8.4,9,8.7,9.5,10],          assetClass: .crypto),
        Holding(ticker: "MSFT", name: "Microsoft",             value: 2_970, dayChangePct: 0.3,  spark: [11,11.2,11.1,11.6,11.8,12],   assetClass: .stocks),
        Holding(ticker: "CASH", name: "Cash & sweep",          value: 3_200, dayChangePct: 0.0,  spark: [5,5,5,5,5,5],                 assetClass: .cash)
    ]
    @Published var range: String = "1M"
    let ranges = ["1D","1W","1M","1Y"]
    var total: Double { holdings.reduce(0) { $0 + $1.value } }
    var dayChangePct: Double {
        guard total > 0 else { return 0 }
        return holdings.reduce(0) { $0 + $1.value * $1.dayChangePct } / total
    }
    var allocations: [Allocation] {
        Dictionary(grouping: holdings, by: { $0.assetClass })
            .map { Allocation(assetClass: $0.key, amount: $0.value.reduce(0) { $0 + $1.value }) }
            .sorted { $0.amount > $1.amount }
    }
}

struct InvestmentsView: View {
    @StateObject private var vm = InvestmentsViewModel()
    private func color(for cls: AssetClass) -> Color {
        switch cls {
        case .stocks: return MilliPalette.accent
        case .etfs:   return Color(red: 0.4,  green: 0.7,  blue: 1.0)
        case .crypto: return Color(red: 0.65, green: 0.55, blue: 1.0)
        case .cash:   return MilliPalette.cardBorder
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                MilliSegmentedPicker(options: vm.ranges, label: { $0 }, selection: $vm.range)
                allocationCard
                holdingsCard
            }.padding()
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Investments")
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Portfolio").font(.subheadline).foregroundStyle(MilliPalette.textSecondary)
            Text(milliCurrency(vm.total)).font(.system(size: 40, weight: .bold, design: .rounded)).foregroundStyle(MilliPalette.textPrimary)
            let up = vm.dayChangePct >= 0
            HStack(spacing: 4) {
                Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                Text(String(format: "%.2f%% today", vm.dayChangePct))
            }.font(.caption.weight(.semibold)).foregroundStyle(up ? MilliPalette.positive : MilliPalette.negative)
        }
    }
    private var allocationCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Allocation").font(.headline).foregroundStyle(MilliPalette.textPrimary)
                HStack(alignment: .center, spacing: 20) {
                    Chart(vm.allocations) { a in
                        SectorMark(angle: .value("Amount", a.amount), innerRadius: .ratio(0.62), angularInset: 2)
                            .foregroundStyle(color(for: a.assetClass))
                    }.frame(width: 130, height: 130)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(vm.allocations) { a in
                            HStack(spacing: 8) {
                                Circle().fill(color(for: a.assetClass)).frame(width: 10, height: 10)
                                Text(a.assetClass.rawValue).font(.caption).foregroundStyle(MilliPalette.textPrimary)
                                Spacer()
                                Text(milliCurrency(a.amount)).font(.caption).foregroundStyle(MilliPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
    private var holdingsCard: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Holdings").font(.headline).foregroundStyle(MilliPalette.textPrimary)
                ForEach(vm.holdings) { h in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(h.ticker).font(.subheadline.weight(.semibold)).foregroundStyle(MilliPalette.textPrimary)
                            Text(h.name).font(.caption2).foregroundStyle(MilliPalette.textSecondary).lineLimit(1)
                        }
                        Spacer()
                        Chart(Array(h.spark.enumerated()), id: \.offset) { item in
                            LineMark(x: .value("i", item.offset), y: .value("v", item.element))
                                .foregroundStyle(h.dayChangePct >= 0 ? MilliPalette.positive : MilliPalette.negative)
                        }
                        .chartXAxis(.hidden).chartYAxis(.hidden).frame(width: 60, height: 28)
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(milliCurrency(h.value)).font(.subheadline).foregroundStyle(MilliPalette.textPrimary)
                            Text(String(format: "%+.1f%%", h.dayChangePct)).font(.caption2)
                                .foregroundStyle(h.dayChangePct >= 0 ? MilliPalette.positive : MilliPalette.negative)
                        }
                    }
                    if h.id != vm.holdings.last?.id { Divider().overlay(MilliPalette.cardBorder) }
                }
            }
        }
    }
}
