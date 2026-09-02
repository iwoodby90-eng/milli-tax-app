import SwiftUI

// MARK: - MapPanel (v1.2)
// One map surface treatment, three states: Mileage Dashboard (11),
// Active Trip (12), Trip Detail (13). Carbon-grid background, cyan route
// lines and pins as embedded light.

struct MapPanel: View {
    enum MapState {
        case idle       // dashboard: live map preview
        case live       // active trip: recording
        case completed  // trip detail: route evidence
    }

    let state: MapState
    var height: CGFloat = 160
    var routePoints: [CGPoint] = []

    var body: some View {
        ZStack {
            // Carbon technical-grid background.
            CarbonGrid()
                .frame(height: height)

            // Route as embedded cyan light.
            if routePoints.count >= 2 {
                RouteShape(points: routePoints)
                    .stroke(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.45), radius: 5)
                    .padding(14)
            }

            VStack {
                HStack {
                    stateChip
                    Spacer(minLength: 0)
                }
                .padding(10)
                Spacer(minLength: 0)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .stroke(MilliColors.borderSubtle, lineWidth: 0.7)
        )
        .accessibilityLabel(mapAccessibility)
    }

    private var stateChip: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state == .live ? MilliColors.cyanGlow : MilliColors.textTertiary)
                .frame(width: 6, height: 6)
            Text(stateLabel)
                .font(MilliFont.label)
                .tracking(0.6)
                .foregroundStyle(state == .live ? MilliColors.cyanGlow : MilliColors.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .overlay(Capsule().stroke(MilliColors.borderSubtle, lineWidth: 0.5))
    }

    private var stateLabel: String {
        switch state {
        case .idle: return "LIVE MAP"
        case .live: return "RECORDING ROUTE"
        case .completed: return "ROUTE EVIDENCE"
        }
    }

    private var mapAccessibility: String {
        switch state {
        case .idle: return "Live mileage map preview"
        case .live: return "Live route map, trip recording in progress"
        case .completed: return "Completed trip route evidence"
        }
    }
}

// MARK: - CarbonGrid
/// Technical carbon-grid backdrop for map surfaces.
struct CarbonGrid: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "10161C"), location: 0),
                    .init(color: MilliColors.carbon, location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Canvas { context, size in
                let grid: CGFloat = 22
                var path = Path()
                var x: CGFloat = 0
                while x <= size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += grid
                }
                var y: CGFloat = 0
                while y <= size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    y += grid
                }
                context.stroke(path, with: .color(Color.white.opacity(0.035)), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - RouteShape
private struct RouteShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}