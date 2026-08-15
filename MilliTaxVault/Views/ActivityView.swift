import SwiftUI
import Charts

struct ActivityView: View {
    @State private var selectedPeriod: String = "Week"
    private let periods = ["Week", "Month", "Quarter"]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Period Picker
                HStack(spacing: 4) {
                    ForEach(periods, id: \.self) { period in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPeriod = period
                            }
                        } label: {
                            Text(period)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(selectedPeriod == period ? .white : MilliColors.secondaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedPeriod == period ? MilliColors.cyan : Color.clear)
                                )
                        }
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(Color(white: 1, opacity: 0.04))
                        .overlay(
                            Capsule()
                                .stroke(Color(white: 0.15), lineWidth: 1)
                        )
                )
                .padding(.top, 60)
                
                // MARK: - Hero Stats Card
                MilliCard {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EARNED")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                                
                                Text("$881")
                                    .font(MilliFont.subHeroNumber)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Rectangle()
                                .fill(Color(white: 0.2))
                                .frame(width: 1, height: 40)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("SET ASIDE")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                                
                                Text("$220")
                                    .font(MilliFont.subHeroNumber)
                                    .foregroundColor(MilliColors.cyan)
                            }
                        }
                        
                        MilliSparkline(data: SampleData.sparklineData, height: 50)
                    }
                }
                
                // MARK: - Income Sources
                VStack(alignment: .leading, spacing: 12) {
                    Text("INCOME SOURCES")
                        .sectionHeaderStyle()
                        .padding(.leading, 4)
                    
                    MilliCard {
                        VStack(spacing: 16) {
                            ForEach(SampleData.incomeSources) { source in
                                IncomeSourceRow(source: source)
                            }
                        }
                    }
                }
                
                // MARK: - Recent Payouts
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT PAYOUTS")
                        .sectionHeaderStyle()
                        .padding(.leading, 4)
                    
                    MilliCard {
                        VStack(spacing: 0) {
                            ForEach(Array(SampleData.payouts.enumerated()), id: \.element.id) { index, payout in
                                PayoutRow(payout: payout)
                                
                                if index < SampleData.payouts.count - 1 {
                                    Divider()
                                        .background(Color(white: 0.15))
                                        .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Tax Summary
                MilliCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("TAX SUMMARY")
                            .font(MilliFont.caption)
                            .foregroundColor(MilliColors.secondaryText)
                            .tracking(1.2)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Effective Rate")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                                
                                Text("25%")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("YTD Set Aside")
                                    .font(MilliFont.caption)
                                    .foregroundColor(MilliColors.secondaryText)
                                
                                Text("$4,820")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text("On Track")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(MilliColors.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(MilliColors.green.opacity(0.15))
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Income Source Row

struct IncomeSourceRow: View {
    let source: IncomeSource
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: source.icon)
                    .font(.system(size: 14))
                    .foregroundColor(source.color)
                
                Text(source.name)
                    .font(MilliFont.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("$\(source.earnings, specifier: "%.2f")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(Int(source.percentage * 100))%")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.secondaryText)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.12))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(source.color)
                        .frame(width: geo.size.width * source.percentage, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Payout Row

struct PayoutRow: View {
    let payout: Payout
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MilliColors.green.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(MilliColors.green)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(payout.platform)
                    .font(MilliFont.body)
                    .foregroundColor(.white)
                
                Text(payout.date)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 3) {
                Text("$\(payout.amount, specifier: "%.2f")")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("-$\(payout.taxWithheld, specifier: "%.2f") tax")
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.cyan)
            }
        }
    }
}
