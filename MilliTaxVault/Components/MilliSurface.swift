import SwiftUI

// MARK: - MilliSurface — Premium Graphite Card Background
// NOT flat gray. Machined financial instrumentation feel.
// LinearGradient + stroke + shadow.

struct MilliSurface: ViewModifier {
    var hasCyanBorder: Bool = false
    var cornerRadius: CGFloat = MilliLayout.cardRadius
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.035),
                                MilliColors.elevated.opacity(0.98),
                                MilliColors.carbon
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                hasCyanBorder
                                    ? MilliColors.cyanGlow.opacity(0.16)
                                    : Color.white.opacity(0.07),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: .black.opacity(0.32), radius: 12, x: 0, y: 5)
            )
    }
}

extension View {
    func milliSurface(hasCyanBorder: Bool = false, cornerRadius: CGFloat = MilliLayout.cardRadius) -> some View {
        self.modifier(MilliSurface(hasCyanBorder: hasCyanBorder, cornerRadius: cornerRadius))
    }
}
