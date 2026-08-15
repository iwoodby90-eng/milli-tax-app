import SwiftUI

// MARK: - MilliSparkline — Compact line chart for hero card

struct MilliSparkline: View {
    let data: [CGFloat]
    var color: Color = MilliColors.cyan
    var height: CGFloat = 40
    var lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 1
            let range = max(maxVal - minVal, 0.001)

            // Line path
            Path { path in
                guard data.count > 1 else { return }
                let stepX = w / CGFloat(data.count - 1)

                for (index, value) in data.enumerated() {
                    let x = stepX * CGFloat(index)
                    let normalizedY = (value - minVal) / range
                    let y = h - (normalizedY * h * 0.8) - (h * 0.1)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

            // Gradient fill below line
            Path { path in
                guard data.count > 1 else { return }
                let stepX = w / CGFloat(data.count - 1)

                for (index, value) in data.enumerated() {
                    let x = stepX * CGFloat(index)
                    let normalizedY = (value - minVal) / range
                    let y = h - (normalizedY * h * 0.8) - (h * 0.1)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: h))
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.addLine(to: CGPoint(x: w, y: h))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.3), color.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(height: height)
    }
}
