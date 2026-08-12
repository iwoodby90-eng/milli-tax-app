import SwiftUI
import Charts

struct LuminousChartStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .chartPlotStyle { plotArea in
                plotArea
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(12)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisTick()
                        .foregroundStyle(.clear)
                    AxisValueLabel() {
                        if let v = value.as(Double.self) {
                            Text(v >= 1000 ? "\(Int(v/1000))K" : "\(Int(v))")
                                .font(.system(size: 9))
                                .foregroundColor(.milliTextTertiary)
                        } else if let s = value.as(String.self) {
                            Text(s)
                                .font(.system(size: 9))
                                .foregroundColor(.milliTextTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.04))
                    AxisTick()
                        .foregroundStyle(.clear)
                    AxisValueLabel() {
                        if let s = value.as(String.self) {
                            Text(s)
                                .font(.system(size: 9))
                                .foregroundColor(.milliTextSecondary)
                        }
                    }
                }
            }
    }
}

extension View {
    func luminousChart() -> some View { self.modifier(LuminousChartStyle()) }
}
