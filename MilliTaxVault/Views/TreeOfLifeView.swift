import SwiftUI

// MARK: - TreeOfLifeView — Visual Glowing Tree Canvas
struct TreeOfLifeView: View {
    @State private var drawProgress: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    
    // Goal nodes pre-seeded
    let goals: [(name: String, amount: String, icon: String, angle: Double, radius: CGFloat)] = [
        ("Buy a home", "$500k", "house.fill", -60, 0.38),
        ("New car", "$40k", "car.fill", -130, 0.35),
        ("Wedding", "$30k", "heart.fill", -20, 0.30),
        ("Baby", "$25k", "figure.2.and.child.holdinghands", -160, 0.28),
        ("Retire", "$1.5M", "star.fill", -90, 0.22),
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "0A0A0C").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("M I L L I")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(6)
                        .opacity(0.5)
                    Text("Tree of Life")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Life events & goals planning")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Tree canvas
                GeometryReader { geo in
                    let W = geo.size.width
                    let H = geo.size.height
                    let cx = W / 2
                    let trunkBottom = H * 0.88
                    let trunkTop = H * 0.55
                    
                    ZStack {
                        // Ambient glow at base
                        Circle()
                            .fill(Color(hex: "003344").opacity(0.5))
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .position(x: cx, y: trunkBottom - 20)
                        
                        // Glow passes (wider, lower opacity)
                        Canvas { ctx, size in
                            drawTree(ctx: ctx, cx: cx, trunkBottom: trunkBottom, trunkTop: trunkTop, W: W, H: H, lineWidth: 6, opacity: 0.15, progress: drawProgress)
                        }
                        .blur(radius: 8)
                        
                        // Main tree lines
                        Canvas { ctx, size in
                            drawTree(ctx: ctx, cx: cx, trunkBottom: trunkBottom, trunkTop: trunkTop, W: W, H: H, lineWidth: 2.5, opacity: 0.9, progress: drawProgress)
                        }
                        
                        // Goal nodes
                        ForEach(Array(goals.enumerated()), id: \.offset) { _, goal in
                            let angle = goal.angle * (.pi / 180)
                            let r = min(W, H) * goal.radius
                            let nx = cx + r * cos(angle)
                            let ny = trunkTop - abs(r * sin(angle)) * 0.8
                            
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "00E5FF"))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: goal.icon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                Text(goal.name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                Text(goal.amount)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "00E5FF"))
                            }
                            .frame(width: 80)
                            .position(x: nx, y: ny)
                            .opacity(drawProgress > 0.7 ? 1 : 0)
                            .animation(.easeIn(duration: 0.4).delay(0.8), value: drawProgress)
                        }
                    }
                }
                
                // Add Life Event button
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add Life Event")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color(hex: "00E5FF"), in: Capsule())
                }
                .padding(.bottom, 120)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) { drawProgress = 1.0 }
        }
    }
    
    func drawTree(ctx: GraphicsContext, cx: CGFloat, trunkBottom: CGFloat, trunkTop: CGFloat, W: CGFloat, H: CGFloat, lineWidth: CGFloat, opacity: CGFloat, progress: CGFloat) {
        var stroke = ctx
        stroke.opacity = Double(opacity)
        let color = Color(hex: "00E5FF")
        
        // Trunk
        var trunk = Path()
        trunk.move(to: CGPoint(x: cx, y: trunkBottom))
        trunk.addLine(to: CGPoint(x: cx, y: trunkTop))
        stroke.stroke(trunk, with: .color(color), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        
        // Branches — 5 bezier curves
        let branches: [(start: CGPoint, control: CGPoint, end: CGPoint)] = [
            (CGPoint(x: cx, y: trunkTop + 20), CGPoint(x: cx - W * 0.15, y: trunkTop - 30), CGPoint(x: cx - W * 0.32, y: trunkTop - 80)),
            (CGPoint(x: cx, y: trunkTop + 30), CGPoint(x: cx + W * 0.15, y: trunkTop - 20), CGPoint(x: cx + W * 0.28, y: trunkTop - 70)),
            (CGPoint(x: cx, y: trunkTop + 10), CGPoint(x: cx - W * 0.08, y: trunkTop - 60), CGPoint(x: cx - W * 0.18, y: trunkTop - 130)),
            (CGPoint(x: cx, y: trunkTop + 25), CGPoint(x: cx + W * 0.10, y: trunkTop - 50), CGPoint(x: cx + W * 0.22, y: trunkTop - 120)),
            (CGPoint(x: cx, y: trunkTop + 15), CGPoint(x: cx - W * 0.04, y: trunkTop - 90), CGPoint(x: cx, y: trunkTop - 150)),
        ]
        
        for branch in branches {
            var p = Path()
            p.move(to: branch.start)
            p.addQuadCurve(to: branch.end, control: branch.control)
            stroke.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: lineWidth * 0.7, lineCap: .round))
        }
    }
}

#Preview {
    TreeOfLifeView()
}
