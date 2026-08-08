import SwiftUI

struct TreeSVGView: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2

            // Trunk
            var trunk = Path()
            trunk.move(to: CGPoint(x: cx, y: h))
            trunk.addLine(to: CGPoint(x: cx, y: h * 0.55))
            context.stroke(trunk, with: .color(Color(hex: "2D5A1B")), lineWidth: 10)

            // Main branches - draw 5 branches spreading from trunk top
            let branches: [(angle: Double, length: CGFloat)] = [
                (-80, h * 0.25), (-50, h * 0.30), (-20, h * 0.22),
                (20, h * 0.28), (60, h * 0.24)
            ]
            for branch in branches {
                let rad = branch.angle * .pi / 180
                var path = Path()
                path.move(to: CGPoint(x: cx, y: h * 0.55))
                let endX = cx + sin(rad) * branch.length
                let endY = h * 0.55 - cos(rad) * branch.length
                path.addLine(to: CGPoint(x: endX, y: endY))
                context.stroke(path, with: .color(Color(hex: "3D7A25")), lineWidth: 4)

                // Leaf cluster at branch end - glowing circle
                let leafRect = CGRect(x: endX - 22, y: endY - 22, width: 44, height: 44)
                context.fill(Path(ellipseIn: leafRect), with: .color(Color(hex: "00C853").opacity(0.85)))

                // Inner highlight
                let innerRect = CGRect(x: endX - 12, y: endY - 12, width: 24, height: 24)
                context.fill(Path(ellipseIn: innerRect), with: .color(Color(hex: "4AE07A").opacity(0.5)))
            }

            // Glowing roots - 3 root lines spreading down
            for offset in [-0.15, 0.0, 0.15] {
                var root = Path()
                root.move(to: CGPoint(x: cx, y: h))
                root.addLine(to: CGPoint(x: cx + CGFloat(offset) * w, y: h * 0.95))
                context.stroke(root, with: .color(Color(hex: "1A3A10").opacity(0.7)), lineWidth: 3)
            }

            // Ground glow
            let groundRect = CGRect(x: cx - 60, y: h - 8, width: 120, height: 16)
            context.fill(Path(ellipseIn: groundRect), with: .color(Color(hex: "00C853").opacity(0.25)))
        }
    }
}

#Preview {
    TreeSVGView()
        .frame(width: 300, height: 280)
        .background(Color(hex: "0A0A0F"))
}
