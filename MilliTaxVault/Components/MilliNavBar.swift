import SwiftUI

// MARK: - MilliTab — Canonical tab definition
enum MilliTab: String, CaseIterable {
    case dashboard
    case activity
    case home
    case wealth
    case transfers
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .activity: return "dollarsign.arrow.circlepath"
        case .home: return "m.circle.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"
        case .transfers: return "car.fill"
        }
    }
    
    var label: String {
        switch self {
        case .dashboard: return "Home"
        case .activity: return "Payouts"
        case .home: return ""
        case .wealth: return "Wealth"
        case .transfers: return "Mileage"
        }
    }
}

// MARK: - MilliNavBar — Dark Graphite + Chrome Bridge Automotive Dashboard
struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    
    private let barHeight: CGFloat = 88
    private let dialSize: CGFloat = 68
    private let dialRise: CGFloat = 22
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // LAYER 1 — Recessed Graphite Tray
            graphiteTray
            
            // LAYER 2 — Sculpted Chrome Bridge (Canvas)
            chromeBridgeCanvas
            
            // LAYER 3 — Tab buttons + Center M Dial
            tabButtonsLayer
        }
        .frame(height: barHeight + dialRise)
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    // MARK: - Layer 1: Graphite Tray
    private var graphiteTray: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "18191C"), Color(hex: "0F1012"), Color(hex: "18191C")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: barHeight)
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    // MARK: - Layer 2: Chrome Bridge (high-contrast metallic)
    private var chromeBridgeCanvas: some View {
        Canvas { context, size in
            let w = size.width
            let h = barHeight
            
            // Quadratic bezier arch path
            var bridgePath = Path()
            bridgePath.move(to: CGPoint(x: 0, y: h * 0.2))
            bridgePath.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.2),
                control: CGPoint(x: w * 0.5, y: h * 0.55)
            )
            bridgePath.addLine(to: CGPoint(x: w, y: h * 0.2 + 8))
            bridgePath.addQuadCurve(
                to: CGPoint(x: 0, y: h * 0.2 + 8),
                control: CGPoint(x: w * 0.5, y: h * 0.55 + 8)
            )
            bridgePath.closeSubpath()
            
            // Fill chrome bridge — HIGH CONTRAST chrome gradient
            context.fill(
                bridgePath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(white: 0.85),
                        Color(white: 0.55),
                        Color(white: 0.25),
                        Color(white: 0.1)
                    ]),
                    startPoint: CGPoint(x: 0, y: h * 0.2),
                    endPoint: CGPoint(x: 0, y: h * 0.2 + 8)
                )
            )
            
            // Top edge specular highlight line (white at 60% opacity)
            var highlightPath = Path()
            highlightPath.move(to: CGPoint(x: 0, y: h * 0.2))
            highlightPath.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.2),
                control: CGPoint(x: w * 0.5, y: h * 0.55)
            )
            
            var highlightCtx = context
            highlightCtx.opacity = 0.6
            highlightCtx.stroke(
                highlightPath,
                with: .color(.white),
                style: StrokeStyle(lineWidth: 1.0)
            )
        }
        .frame(height: barHeight)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
    }
    
    // MARK: - Layer 3: Tab Buttons + M Dial
    private var tabButtonsLayer: some View {
        HStack(spacing: 0) {
            // Left tabs: Home, Payouts
            tabButton(tab: .dashboard)
            tabButton(tab: .activity)
            
            // Center M Dial (raised)
            mDialButton
                .offset(y: -dialRise)
            
            // Right tabs: Wealth, Mileage
            tabButton(tab: .wealth)
            tabButton(tab: .transfers)
        }
        .frame(height: barHeight)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
    
    // MARK: - Tab Button
    private func tabButton(tab: MilliTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(selectedTab == tab ? Color(hex: "00E5FF") : Color.white.opacity(0.55))
                    .shadow(
                        color: selectedTab == tab ? Color(hex: "00E5FF").opacity(0.7) : Color.clear,
                        radius: selectedTab == tab ? 6 : 0
                    )
                
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTab == tab ? Color(hex: "00E5FF") : Color.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
    
    // MARK: - Center M Dial (Upgraded — deeper depth, segmented cyan dot ring)
    private var mDialButton: some View {
        Button(action: { selectedTab = .home }) {
            ZStack {
                // Outer chrome ring with radial gradient for depth
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.7), Color(white: 0.3), Color(white: 0.15)],
                            center: .center,
                            startRadius: 26,
                            endRadius: 34
                        )
                    )
                    .frame(width: 68, height: 68)
                    .shadow(color: .black.opacity(0.8), radius: 6, x: 0, y: 4)
                
                // Angular chrome bezel stroke overlay
                Circle()
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: Color(hex: "E0E4E8"), location: 0.0),
                                .init(color: Color(hex: "7A7E84"), location: 0.25),
                                .init(color: Color(hex: "3A3C40"), location: 0.5),
                                .init(color: Color(hex: "7A7E84"), location: 0.75),
                                .init(color: Color(hex: "E0E4E8"), location: 1.0)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 68, height: 68)
                
                // Segmented cyan dot ring (LED dots)
                ForEach(0..<24, id: \.self) { i in
                    let angle = Double(i) * (360.0 / 24.0)
                    Circle()
                        .fill(Color.cyan.opacity(i % 3 == 0 ? 0.9 : 0.3))
                        .frame(width: i % 3 == 0 ? 3 : 2, height: i % 3 == 0 ? 3 : 2)
                        .offset(y: -27)
                        .rotationEffect(.degrees(angle))
                }
                
                // Black glass face
                Circle()
                    .fill(Color(white: 0.05))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.2), lineWidth: 0.5)
                    )
                
                // Angular M with cyan gradient glow
                Text("M")
                    .font(.system(size: 22, weight: .black, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.white.opacity(0.9), Color.cyan.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.8), radius: 4)
            }
            .frame(width: 68, height: 68)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.dashboard))
        }
    }
}
