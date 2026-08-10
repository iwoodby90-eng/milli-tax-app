import SwiftUI

struct RetirementProjectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var contributionPercent: Double = 15
    @State private var retirementAge: Double = 62
    @State private var selectedScenario: Scenario = .moderate
    
    enum Scenario: String, CaseIterable {
        case conservative = "Conservative"
        case moderate = "Moderate"
        case aggressive = "Aggressive"
        
        var rate: Double {
            switch self {
            case .conservative: return 0.06
            case .moderate: return 0.07
            case .aggressive: return 0.08
            }
        }
        
        var rateLabel: String {
            switch self {
            case .conservative: return "6%"
            case .moderate: return "7%"
            case .aggressive: return "8%"
            }
        }
    }
    
    private let currentAge = 34
    private let currentSalary: Double = 65000
    
    private var yearsToRetirement: Double { retirementAge - Double(currentAge) }
    private var annualContribution: Double { currentSalary * (contributionPercent / 100) }
    private var retirementYear: Int { 2026 + Int(yearsToRetirement) }
    
    private var totalContributions: Double {
        annualContribution * yearsToRetirement
    }
    
    private var estimatedValue: Double {
        let r = selectedScenario.rate
        let n = yearsToRetirement
        guard r > 0, n > 0 else { return 0 }
        // Future value of annuity formula
        return annualContribution * ((pow(1 + r, n) - 1) / r)
    }
    
    private var totalGrowth: Double {
        estimatedValue - totalContributions
    }
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Adjust Your Plan", showBack: true, onBack: { dismiss() })
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Contribution Slider
                        MilliCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("CONTRIBUTION PERCENTAGE")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundColor(.milliTextSecondary)
                                    Spacer()
                                    Text("\(Int(contributionPercent))%")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.milliCyan)
                                }
                                
                                Slider(value: $contributionPercent, in: 0...50, step: 1)
                                    .accentColor(.milliCyan)
                                
                                HStack {
                                    Text("0%")
                                        .font(.system(size: 10))
                                        .foregroundColor(.milliTextTertiary)
                                    Spacer()
                                    Text("50%")
                                        .font(.system(size: 10))
                                        .foregroundColor(.milliTextTertiary)
                                }
                            }
                        }
                        
                        // Retirement Age Slider
                        MilliCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("RETIREMENT AGE")
                                        .font(.system(size: 11, weight: .bold))
                                        .tracking(0.5)
                                        .foregroundColor(.milliTextSecondary)
                                    Spacer()
                                    Text("\(Int(retirementAge))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.milliCyan)
                                }
                                
                                Slider(value: $retirementAge, in: 55...70, step: 1)
                                    .accentColor(.milliCyan)
                                
                                HStack {
                                    Text("55")
                                        .font(.system(size: 10))
                                        .foregroundColor(.milliTextTertiary)
                                    Spacer()
                                    Text("70")
                                        .font(.system(size: 10))
                                        .foregroundColor(.milliTextTertiary)
                                }
                            }
                        }
                        
                        // Updated Projection
                        MilliCard {
                            VStack(spacing: 14) {
                                Text("UPDATED PROJECTION")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                projectionRow(label: "Retirement Year", value: "\(retirementYear)")
                                projectionRow(label: "Estimated Value", value: "$\(formatCompact(estimatedValue))", color: .milliSuccess)
                                projectionRow(label: "Total Contributions", value: "$\(formatCompact(totalContributions))")
                                projectionRow(label: "Total Growth", value: "$\(formatCompact(totalGrowth))", color: .milliCyan)
                            }
                        }
                        
                        // Scenarios
                        MilliCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PROJECTION SCENARIOS")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                
                                ForEach(Scenario.allCases, id: \.self) { scenario in
                                    Button(action: { selectedScenario = scenario }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(scenario.rawValue)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(selectedScenario == scenario ? .milliCyan : .white)
                                                Text("Annual return: \(scenario.rateLabel)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.milliTextSecondary)
                                            }
                                            Spacer()
                                            if selectedScenario == scenario {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.milliCyan)
                                            } else {
                                                Circle()
                                                    .stroke(Color.milliCardBorder, lineWidth: 1.5)
                                                    .frame(width: 18, height: 18)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if scenario != Scenario.allCases.last {
                                        Divider().background(Color.milliCardBorder)
                                    }
                                }
                            }
                        }
                        
                        // Apply Button
                        Button(action: { dismiss() }) {
                            Text("Apply Adjustments")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.milliCyan)
                                .cornerRadius(14)
                                .shadow(color: Color.milliCyan.opacity(0.3), radius: 12, x: 0, y: 4)
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
    
    private func projectionRow(label: String, value: String, color: Color = .white) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.milliTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)
        }
    }
    
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.0fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}
