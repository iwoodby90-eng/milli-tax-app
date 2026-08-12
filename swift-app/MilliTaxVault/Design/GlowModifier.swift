import SwiftUI

// A reusable neon/glass glow effect that stacks multiple soft shadows.
struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.35), radius: radius * 0.6, x: 0, y: 0)
            .shadow(color: color.opacity(0.18), radius: radius * 0.3, x: 0, y: 0)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat) -> some View {
        self.modifier(GlowModifier(color: color, radius: radius))
    }
}
