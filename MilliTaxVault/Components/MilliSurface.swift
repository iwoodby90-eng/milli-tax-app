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
                            stops: [
                                .init(color: Color.white.opacity(0.035), location: 0.0),
                                .init(color: Color(hex: "12191F").opacity(0.98), location: 0.18),
                                .init(color: Color(hex: "0E1114"))
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                hasCyanBorder
                                    ? Color(hex: "00E5FF").opacity(0.16)
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

// MARK: - MilliRecessedCard — Tier 2 Black-Glass Surface
// MILLI Deviation/Acceptance Spec v1 (Aug 28, 2026), section 3:
// recessed black-glass family for metric tiles and list rows.
// Obsidian fill, inner shadow (recessed into the background),
// 0.5 pt white 5% border.

struct MilliRecessedCard: ViewModifier {
    var padding: CGFloat = 14
    var cornerRadius: CGFloat = MilliLayout.cardRadius

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(hex: "07090B"))
            )
            .overlay(
                // Inner shadow: the tile sits below the background plane.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.black.opacity(0.60), lineWidth: 2)
                    .blur(radius: 3)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    )
            )
            .overlay(
                // 0.5 pt white 5% border.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
            )
    }
}

extension View {
    func milliRecessedCard(padding: CGFloat = 14, cornerRadius: CGFloat = MilliLayout.cardRadius) -> some View {
        self.modifier(MilliRecessedCard(padding: padding, cornerRadius: cornerRadius))
    }
}
