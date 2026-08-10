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
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Milli Cents", showBack: true, onBack: { dismiss() })
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Input Section
                        MilliCard {
                            VStack(spacing: 14) {
                                Text("OFFER DETAILS")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                inputField(label: "Offer Amount", placeholder: "$0.00", text: $offerAmount, prefix: "$")
                                inputField(label: "Estimated Miles", placeholder: "0", text: $estimatedMiles)
                                inputField(label: "Dead Miles (to pickup)", placeholder: "0", text: $deadMiles)
                                inputField(label: "Return Miles", placeholder: "0", text: $returnMiles)
                                inputField(label: "Fuel Cost / Mile", placeholder: "0.196", text: $fuelCostPerMile, prefix: "$")
                            }
                        }
                        
                        // Results Section
                        MilliCard {
                            VStack(spacing: 12) {
                                Text("BREAKDOWN")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                resultRow(label: "Total Miles", value: String(format: "%.1f mi", totalMiles))
                                resultRow(label: "Fuel Cost", value: String(format: "-$%.2f", fuelCost), color: .milliError)
                                resultRow(label: "Tax Impact (25%)", value: String(format: "-$%.2f", taxImpact), color: .milliWarning)
                                
                                Divider().background(Color.milliCardBorder)
                                
                                resultRow(label: "Net Profit", value: String(format: "$%.2f", netProfit), color: isProfitable ? .milliSuccess : .milliError, bold: true)
                                resultRow(label: "Profit Per Mile", value: String(format: "$%.3f/mi", profitPerMile), color: isProfitable ? .milliSuccess : .milliError)
                            }
                        }
                        
                        // Verdict Card
                        if offer > 0 && totalMiles > 0 {
                            MilliCard {
                                VStack(spacing: 8) {
                                    Text(isProfitable ? "GO" : "PASS")
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(isProfitable ? .milliSuccess : .milliError)
                                        .shadow(color: (isProfitable ? Color.milliSuccess : Color.milliError).opacity(0.5), radius: 12)
                                    
                                    Text(isProfitable ? "This offer is profitable." : "This offer loses money.")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.milliTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // AI Insight
                        MilliCard {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.milliCyan)
                                    .frame(width: 28, height: 28)
                                    .background(Color.milliCyan.opacity(0.1))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Milli AI Insight")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.milliCyan)
                                    
                                    Text(aiInsight)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(.milliTextSecondary)
                                        .lineSpacing(3)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var aiInsight: String {
        if totalMiles == 0 || offer == 0 {
            return "Enter your offer details above to get a profitability analysis."
        }
        if profitPerMile > 0.50 {
            return "Strong offer. At $\(String(format: "%.2f", profitPerMile))/mile, this is well above the profitable threshold. Accept this one."
        } else if isProfitable {
            return "Marginally profitable. Consider if the time investment is worth the return. Dead miles are eating into your margin."
        } else {
            return "This offer costs you money after fuel and taxes. The dead miles make this a net negative. Decline and wait for a better batch."
        }
    }
    
    private func inputField(label: String, placeholder: String, text: Binding<String>, prefix: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.milliTextSecondary)
            
            HStack(spacing: 6) {
                if let prefix = prefix {
                    Text(prefix)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.milliTextTertiary)
                }
                TextField(placeholder, text: text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.milliBackground)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.milliCardBorder, lineWidth: 0.5)
            )
        }
    }
    
    private func resultRow(label: String, value: String, color: Color = .white, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.milliTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: bold ? .bold : .semibold))
                .foregroundColor(color)
        }
    }
}
