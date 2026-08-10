import SwiftUI
import Charts

struct WealthOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let netWorth: Double = 48_620.00
    private let monthChange: Double = 2_340.00
    
    private let segments: [(label: String, value: Double, color: Color)] = [
        ("Investments", 22802.0, .milliCyan),
        ("Retirement", 14200.0, Color(hex: "3B82F6")),
        ("Savings Goals", 8400.0, Color(hex: "A855F7")),
        ("Cash", 3218.0, Color(hex: "6B7280")),
    ]
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                MilliPageHeader(title: "Wealth Overview", showBack: true, onBack: { dismiss() })
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Net Worth Header
                        MilliCard {
                            VStack(spacing: 8) {
                                Text("TOTAL NET WORTH")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                
                                Text("$\(String(format: "%.2f", netWorth))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("+$\(String(format: "%.2f", monthChange)) this month")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.milliSuccess)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        
                        // Donut Chart
                        MilliCard {
                            VStack(spacing: 16) {
                                Chart(segments, id: \.label) { segment in
                                    SectorMark(
                                        angle: .value("Value", segment.value),
                                        innerRadius: .ratio(0.65),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(segment.color)
                                    .cornerRadius(4)
                                }
                                .frame(height: 200)
                                
                                // Legend
                                VStack(spacing: 8) {
                                    ForEach(segments, id: \.label) { segment in
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(segment.color)
                                                .frame(width: 10, height: 10)
                                            Text(segment.label)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("$\(String(format: "%.0f", segment.value))")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.milliTextSecondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Projection Cards
                        MilliCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .font(.system(size: 14))
                                            .foregroundColor(.milliCyan)
                                        Text("Retirement Projection")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Text("Projected value at age 65")
                                        .font(.system(size: 11))
                                        .foregroundColor(.milliTextSecondary)
                                }
                                Spacer()
                                Text("$1.42M")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.milliSuccess)
                            }
                        }
                        
                        MilliCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "target")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "A855F7"))
                                        Text("Savings Goals")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Text("3 goals on track")
                                        .font(.system(size: 11))
                                        .foregroundColor(.milliTextSecondary)
                                }
                                Spacer()
                                Text("$8,400")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(hex: "A855F7"))
                            }
                        }
                        
                        MilliCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.up.forward.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.milliCyan)
                                        Text("Monthly Progress")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    Text("Invested across all accounts")
                                        .font(.system(size: 11))
                                        .foregroundColor(.milliTextSecondary)
                                }
                                Spacer()
                                Text("$1,850")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.milliCyan)
                            }
                        }
                        
                        // Future Net Worth
                        MilliCard {
                            VStack(spacing: 8) {
                                Text("FUTURE NET WORTH")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(0.5)
                                    .foregroundColor(.milliTextSecondary)
                                
                                Text("$1,680,000")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.milliCyan)
                                    .shadow(color: Color.milliCyan.opacity(0.3), radius: 8)
                                
                                Text("Projected at age 65")
                                    .font(.system(size: 13))
                                    .foregroundColor(.milliTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
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
}
