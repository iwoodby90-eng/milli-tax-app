import SwiftUI
import Charts

// MARK: - Area Chart (Net Worth Growth)

struct MilliAreaChart: View {
    let data: [ChartDataPoint]
    let height: CGFloat
    
    init(data: [ChartDataPoint], height: CGFloat = 200) {
        self.data = data
        self.height = height
    }
    
    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Day", point.day),
                y: .value("Value", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [MilliColors.cyan.opacity(0.3), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
            
            LineMark(
                x: .value("Day", point.day),
                y: .value("Value", point.value)
            )
            .foregroundStyle(MilliColors.cyan)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
        .shadow(color: MilliColors.cyan.opacity(0.4), radius: 8)
    }
}
