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
    
    // MARK: - Layer 2: Chrome Bridge
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
            
            // Fill chrome bridge
            context.fill(
                bridgePath,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "4A4E54"), Color(hex: "2A2E34"), Color(hex: "3E4248")]),
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: w, y: 0)
                )
            )
            
            // Top edge highlight line
            var highlightPath = Path()
            highlightPath.move(to: CGPoint(x: 0, y: h * 0.2))
            highlightPath.addQuadCurve(
                to: CGPoint(x: w, y: h * 0.2),
                control: CGPoint(x: w * 0.5, y: h * 0.55)
            )
            
            var highlightCtx = context
            highlightCtx.opacity = 0.9
            highlightCtx.stroke(
                highlightPath,
                with: .color(Color(hex: "C8CACE")),
                style: StrokeStyle(lineWidth: 1.5)
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
    
    // MARK: - Center M Dial
    private var mDialButton: some View {
        Button(action: { selectedTab = .home }) {
            ZStack {
                // Outer chrome bezel ring
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
                    .frame(width: dialSize, height: dialSize)
                
                // Inner face
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "28292C"), Color(hex: "0F1012")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 34
                        )
                    )
                    .frame(width: dialSize - 6, height: dialSize - 6)
                
                // Segmented tick ring — 24 ticks
                ForEach(0..<24, id: \.self) { i in
                    let angle = Double(i) * (360.0 / 24.0)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(hex: "00E5FF").opacity(0.7))
                        .frame(width: 3, height: 6)
                        .offset(y: -31)
                        .rotationEffect(.degrees(angle))
                }
                
                // Glowing cyan M
                Text("M")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "00E5FF"))
                    .shadow(color: Color(hex: "00E5FF").opacity(0.9), radius: 6)
            }
            .frame(width: dialSize + 6, height: dialSize + 6)
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
