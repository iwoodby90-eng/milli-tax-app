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
    private var estimatedValue: Double {
        let r = selectedScenario.rate
        let n = yearsToRetirement
        guard r > 0, n > 0 else { return 0 }
        return annualContribution * ((pow(1 + r, n) - 1) / r)
    }
    private var totalContributions: Double { annualContribution * yearsToRetirement }
    private var totalGrowth: Double { estimatedValue - totalContributions }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Contribution Slider
                DKCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Contribution")
                                .font(.subheadline)
                                .foregroundStyle(MilliPalette.textSecondary)
                            Spacer()
                            Text("\(Int(contributionPercent))%")
                                .font(.headline)
                                .foregroundStyle(MilliPalette.accent)
                        }
                        Slider(value: $contributionPercent, in: 0...50, step: 1)
                            .tint(MilliPalette.accent)
                    }
                }

                // Retirement Age Slider
                DKCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Retirement Age")
                                .font(.subheadline)
                                .foregroundStyle(MilliPalette.textSecondary)
                            Spacer()
                            Text("\(Int(retirementAge))")
                                .font(.headline)
                                .foregroundStyle(MilliPalette.accent)
                        }
                        Slider(value: $retirementAge, in: 55...70, step: 1)
                            .tint(MilliPalette.accent)
                    }
                }

                // Live Calculation
                DKCard {
                    VStack(spacing: 12) {
                        Text("Updated Projection")
                            .font(.headline)
                            .foregroundStyle(MilliPalette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        projRow("Estimated Value", formatCompact(estimatedValue), MilliPalette.positive)
                        projRow("Total Contributions", formatCompact(totalContributions), MilliPalette.textPrimary)
                        projRow("Total Growth", formatCompact(totalGrowth), MilliPalette.accent)
                    }
                }

                // Scenarios
                DKCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scenarios")
                            .font(.headline)
                            .foregroundStyle(MilliPalette.textPrimary)

                        ForEach(Scenario.allCases, id: \.self) { scenario in
                            Button(action: { selectedScenario = scenario }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(scenario.rawValue)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(selectedScenario == scenario ? MilliPalette.accent : MilliPalette.textPrimary)
                                        Text("Annual return: \(scenario.rateLabel)")
                                            .font(.caption)
                                            .foregroundStyle(MilliPalette.textSecondary)
                                    }
                                    Spacer()
                                    if selectedScenario == scenario {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(MilliPalette.accent)
                                    } else {
                                        Circle()
                                            .stroke(MilliPalette.cardBorder, lineWidth: 1.5)
                                            .frame(width: 18, height: 18)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)

                            if scenario != Scenario.allCases.last {
                                Divider().overlay(MilliPalette.cardBorder)
                            }
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: MilliPalette.radius, style: .continuous)
                        .stroke(MilliPalette.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Adjust Plan")
    }

    private func projRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(MilliPalette.textSecondary)
            Spacer()
            Text(value).font(.subheadline.weight(.bold)).foregroundStyle(color)
        }
    }

    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.2fM", value / 1_000_000) }
        else if value >= 1000 { return String(format: "$%.0fK", value / 1000) }
        return String(format: "$%.0f", value)
    }
}
