import SwiftUI
import Charts

// MARK: - MilliSparkline — Animated Cashflow Chart
// LineMark + AreaMark with catmullRom interpolation.
// Cyan line ~1.5pt, subtle under-fill gradient, no axes/labels/grid.

struct MilliSparkline: View {
    let data: [Double]
    @State private var animationProgress: CGFloat = 0
    
    init(data: [Double] = [800, 920, 870, 1040, 990, 1180, 1365]) {
        self.data = data
    }
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Amount", value * animationProgress)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(MilliColors.cyan)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                
                AreaMark(
                    x: .value("Day", index),
                    y: .value("Amount", value * animationProgress)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            MilliColors.cyan.opacity(0.25),
                            MilliColors.cyan.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
}
