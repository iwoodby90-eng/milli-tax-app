import SwiftUI

struct TreeOfLifeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var pulsePhase: CGFloat = 0
    @State private var glowOpacity: Double = 0.4
    
    private let projectedValue: Double = 1_420_000
    private let contributions: Double = 284_820
    private let growth: Double = 1_135_180
    
    private var isElite: Bool {
        appState.currentUser?.tier?.lowercased() == "elite"
    }
    
    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()
            
            if isElite {
                eliteContent
            } else {
                lockedContent
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Elite Content
    
    private var eliteContent: some View {
        VStack(spacing: 0) {
            MilliPageHeader(title: "Tree of Life", showBack: true, onBack: { dismiss() })
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer().frame(height: 20)
                    
                    // Tree
                    ZStack {
                        // Tree shape
                        TreeShape()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.milliCyan.opacity(0.6), Color.milliCyan.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: 260, height: 300)
                        
                        // Glowing leaves
                        ForEach(0..<12, id: \.self) { i in
                            Circle()
                                .fill(Color.milliCyan)
                                .frame(width: 6, height: 6)
                                .blur(radius: 2)
                                .opacity(glowOpacity + Double(i % 3) * 0.1)
                                .offset(leafOffset(index: i))
                        }
                        
                        // Center overlay
                        VStack(spacing: 6) {
                            Text("Current Projected Value")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.milliTextSecondary)
                            
                            Text("$\(formatLarge(projectedValue))")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: Color.milliCyan.opacity(0.4), radius: 10)
                            
                            Text("at age 65")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.milliCyan)
                        }
                    }
                    .frame(height: 320)
                    
                    // Stat Pills
                    HStack(spacing: 12) {
                        statPill(label: "Contributions", value: "$\(formatCompact(contributions))")
                        statPill(label: "Growth", value: "$\(formatCompact(growth))")
                    }
                    .padding(.horizontal, 20)
                    
                    // Inspirational quote
                    Text("Your future grows with every smart decision today.")
                        .font(.system(size: 14, weight: .regular).italic())
                        .foregroundColor(.milliTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.9
            }
        }
    }
    
    // MARK: - Locked Content
    
    private var lockedContent: some View {
        VStack(spacing: 0) {
            MilliPageHeader(title: "Tree of Life", showBack: true, onBack: { dismiss() })
            
            Spacer()
            
            ZStack {
                // Blurred tree preview
                TreeShape()
                    .stroke(Color.milliCyan.opacity(0.15), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 260, height: 300)
                    .blur(radius: 8)
                
                // Lock overlay
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.milliCyan)
                    
                    Text("Unlock with MILLI Elite")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("The Tree of Life visualization is exclusive\nto MILLI Elite members.")
                        .font(.system(size: 14))
                        .foregroundColor(.milliTextSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {}) {
                        Text("Upgrade to Elite")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.milliCyan)
                            .cornerRadius(12)
                            .shadow(color: Color.milliCyan.opacity(0.3), radius: 8)
                    }
                    .padding(.top, 8)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helpers
    
    private func leafOffset(index: Int) -> CGSize {
        let positions: [CGSize] = [
            CGSize(width: -80, height: -100),
            CGSize(width: -50, height: -120),
            CGSize(width: -20, height: -130),
            CGSize(width: 20, height: -125),
            CGSize(width: 55, height: -115),
            CGSize(width: 85, height: -95),
            CGSize(width: -65, height: -70),
            CGSize(width: -30, height: -80),
            CGSize(width: 30, height: -85),
            CGSize(width: 65, height: -65),
            CGSize(width: -45, height: -50),
            CGSize(width: 45, height: -45),
        ]
        return positions[index % positions.count]
    }
    
    private func statPill(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.milliTextSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.milliCyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.milliCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.milliCardBorder, lineWidth: 0.5)
        )
    }
    
    private func formatLarge(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func formatCompact(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1000 {
            return String(format: "%.0fK", value / 1000)
        }
        return String(format: "%.0f", value)
    }
}

// MARK: - Tree Shape (SwiftUI Path)

struct TreeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w / 2
        
        // Trunk
        let trunkWidth: CGFloat = 12
        path.move(to: CGPoint(x: cx - trunkWidth / 2, y: h))
        path.addLine(to: CGPoint(x: cx - trunkWidth / 2, y: h * 0.55))
        path.addLine(to: CGPoint(x: cx + trunkWidth / 2, y: h * 0.55))
        path.addLine(to: CGPoint(x: cx + trunkWidth / 2, y: h))
        
        // Main branches (left)
        path.move(to: CGPoint(x: cx, y: h * 0.6))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.35, y: h * 0.25), control: CGPoint(x: cx - w * 0.2, y: h * 0.45))
        
        path.move(to: CGPoint(x: cx, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.25, y: h * 0.12), control: CGPoint(x: cx - w * 0.15, y: h * 0.32))
        
        path.move(to: CGPoint(x: cx, y: h * 0.45))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.1, y: h * 0.05), control: CGPoint(x: cx - w * 0.08, y: h * 0.25))
        
        // Main branches (right)
        path.move(to: CGPoint(x: cx, y: h * 0.6))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.35, y: h * 0.25), control: CGPoint(x: cx + w * 0.2, y: h * 0.45))
        
        path.move(to: CGPoint(x: cx, y: h * 0.5))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.25, y: h * 0.12), control: CGPoint(x: cx + w * 0.15, y: h * 0.32))
        
        path.move(to: CGPoint(x: cx, y: h * 0.45))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.1, y: h * 0.05), control: CGPoint(x: cx + w * 0.08, y: h * 0.25))
        
        return path
    }
}
