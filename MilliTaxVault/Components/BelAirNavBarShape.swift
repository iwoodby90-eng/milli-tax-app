import SwiftUI

// MARK: - BelAirNavBarShape — Custom Path-based Sculpted Metallic Bridge
// References: 1954 Bel Air dashboard chrome bezel.
// The shape creates a wide concave arc in the center for the M dial to nest into,
// with smooth convex "wings" on each side that curve upward at the edges.
// This gives the physical hardware instrument panel feel.

struct BelAirNavBarShape: Shape {
    /// Depth of the center concave notch (how far down the center dips)
    var notchDepth: CGFloat = 26
    /// Width of the center notch opening
    var notchWidth: CGFloat = 100
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        let midX = w / 2
        
        // Start from top-left with a slight upward curve (wing tip)
        path.move(to: CGPoint(x: 0, y: 8))
        
        // Left wing — subtle convex rise
        path.addQuadCurve(
            to: CGPoint(x: midX - notchWidth / 2, y: 3),
            control: CGPoint(x: w * 0.2, y: 0)
        )
        
        // Center concave notch — smooth bezier that dips down for the M button
        path.addCurve(
            to: CGPoint(x: midX + notchWidth / 2, y: 3),
            control1: CGPoint(x: midX - notchWidth * 0.3, y: notchDepth),
            control2: CGPoint(x: midX + notchWidth * 0.3, y: notchDepth)
        )
        
        // Right wing — subtle convex rise
        path.addQuadCurve(
            to: CGPoint(x: w, y: 8),
            control: CGPoint(x: w * 0.8, y: 0)
        )
        
        // Close the bottom (flat bottom of the bar)
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - BelAirSpecularEdge — Top edge highlight shape for specular reflection
// A thin strip along the top contour of the nav bar shape for the chrome edge catch.

struct BelAirSpecularEdge: Shape {
    var notchDepth: CGFloat = 26
    var notchWidth: CGFloat = 100
    var thickness: CGFloat = 1.5
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let midX = w / 2
        
        // Trace same top contour as BelAirNavBarShape
        path.move(to: CGPoint(x: 0, y: 8))
        
        path.addQuadCurve(
            to: CGPoint(x: midX - notchWidth / 2, y: 3),
            control: CGPoint(x: w * 0.2, y: 0)
        )
        
        path.addCurve(
            to: CGPoint(x: midX + notchWidth / 2, y: 3),
            control1: CGPoint(x: midX - notchWidth * 0.3, y: notchDepth),
            control2: CGPoint(x: midX + notchWidth * 0.3, y: notchDepth)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: w, y: 8),
            control: CGPoint(x: w * 0.8, y: 0)
        )
        
        // Return along slightly offset path (thickness below)
        path.addLine(to: CGPoint(x: w, y: 8 + thickness))
        
        path.addQuadCurve(
            to: CGPoint(x: midX + notchWidth / 2, y: 3 + thickness),
            control: CGPoint(x: w * 0.8, y: thickness)
        )
        
        path.addCurve(
            to: CGPoint(x: midX - notchWidth / 2, y: 3 + thickness),
            control1: CGPoint(x: midX + notchWidth * 0.3, y: notchDepth + thickness),
            control2: CGPoint(x: midX - notchWidth * 0.3, y: notchDepth + thickness)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: 0, y: 8 + thickness),
            control: CGPoint(x: w * 0.2, y: thickness)
        )
        
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B")
        VStack {
            Spacer()
            ZStack {
                BelAirNavBarShape()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2A2E33"), Color(hex: "1A1D22"), Color(hex: "0F1215")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 90)
                
                BelAirSpecularEdge()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 90)
            }
        }
    }
    .ignoresSafeArea()
}
