import SwiftUI

struct MilliCentsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var offerAmount: String = ""
    @State private var estimatedMiles: String = ""
    @State private var deadMiles: String = ""
    @State private var returnMiles: String = ""
    @State private var fuelCostPerMile: String = "0.196"

    private var offer: Double { Double(offerAmount) ?? 0 }
    private var estMiles: Double { Double(estimatedMiles) ?? 0 }
    private var dead: Double { Double(deadMiles) ?? 0 }
    private var ret: Double { Double(returnMiles) ?? 0 }
    private var fuelRate: Double { Double(fuelCostPerMile) ?? 0.196 }

    private var totalMiles: Double { estMiles + dead + ret }
    private var fuelCost: Double { totalMiles * fuelRate }
    private var netBeforeTax: Double { offer - fuelCost }
    private var taxImpact: Double { max(0, netBeforeTax * 0.25) }
    private var netProfit: Double { netBeforeTax - taxImpact }
    private var profitPerMile: Double { totalMiles > 0 ? netProfit / totalMiles : 0 }
    private var isProfitable: Bool { netProfit > 0 }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Input
                DKCard {
                    VStack(spacing: 14) {
                        Text("Offer Details")
                            .font(.headline)
                            .foregroundStyle(MilliPalette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        inputField(label: "Offer Amount", text: $offerAmount, prefix: "$")
                        inputField(label: "Estimated Miles", text: $estimatedMiles)
                        inputField(label: "Dead Miles (to pickup)", text: $deadMiles)
                        inputField(label: "Return Miles", text: $returnMiles)
                        inputField(label: "Fuel Cost / Mile", text: $fuelCostPerMile, prefix: "$")
                    }
                }

                // Results
                if offer > 0 && totalMiles > 0 {
                    HStack(spacing: 10) {
                        MilliStatTile(title: "Fuel Cost", value: milliCurrency(fuelCost, fraction: 2), accent: MilliPalette.negative)
                        MilliStatTile(title: "Tax Impact", value: milliCurrency(taxImpact, fraction: 2), accent: MilliPalette.negative)
                    }
                    HStack(spacing: 10) {
                        MilliStatTile(title: "Net Profit", value: milliCurrency(netProfit, fraction: 2), accent: isProfitable ? MilliPalette.positive : MilliPalette.negative)
                        MilliStatTile(title: "Per Mile", value: String(format: "$%.3f", profitPerMile), accent: isProfitable ? MilliPalette.positive : MilliPalette.negative)
                    }

                    // Verdict
                    DKCard {
                        VStack(spacing: 8) {
                            Text(isProfitable ? "GO" : "PASS")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(isProfitable ? MilliPalette.positive : MilliPalette.negative)
                                .shadow(color: (isProfitable ? MilliPalette.positive : MilliPalette.negative).opacity(0.5), radius: 12)
                            Text(isProfitable ? "This offer is profitable." : "This offer loses money.")
                                .font(.subheadline)
                                .foregroundStyle(MilliPalette.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Milli Cents")
    }

    private func inputField(label: String, text: Binding<String>, prefix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(MilliPalette.textSecondary)
            HStack(spacing: 6) {
                if let prefix = prefix {
                    Text(prefix)
                        .font(.subheadline)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
                TextField("0", text: text)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(MilliPalette.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(MilliPalette.cardBorder, lineWidth: 1)
            )
        }
    }
}
