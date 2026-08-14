import SwiftUI
import Charts

// MARK: - MilliSparkline — Animated Cashflow Chart
// LineMark + AreaMark with catmullRom interpolation.
// Cyan line ~1.5pt, subtle under-fill gradient, no axes/labels/grid.
// Supports both [Double] and [ChartDataPoint] data sources.

struct MilliSparkline: View {
    private let indexedData: [(index: Int, value: Double)]
    let height: CGFloat
    @State private var animationProgress: CGFloat = 0
    
    // Initializer for [Double] data (HomeView cashflow)
    init(data: [Double] = [800, 920, 870, 1040, 990, 1180, 1365], height: CGFloat = 60) {
        self.indexedData = data.enumerated().map { ($0.offset, $0.element) }
        self.height = height
    }
    
    // Initializer for [ChartDataPoint] data (Wealth/Activity sparklines)
    init(data: [ChartDataPoint], height: CGFloat = 60) {
        self.indexedData = data.map { (Int($0.day), $0.value) }
        self.height = height
    }
    
    var body: some View {
        Chart {
            ForEach(indexedData, id: \.index) { item in
                LineMark(
                    x: .value("Day", item.index),
                    y: .value("Amount", item.value * animationProgress)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(MilliColors.cyan)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
                
                AreaMark(
                    x: .value("Day", item.index),
                    y: .value("Amount", item.value * animationProgress)
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
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
}
