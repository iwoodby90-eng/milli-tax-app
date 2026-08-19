import SwiftUI

// MARK: - MilliCard
// Premium graphite/black-glass surface shared by the whole app.
// The goal is depth without visual noise: machined edge, restrained cyan atmosphere,
// and enough separation from the obsidian canvas to read cleanly on OLED displays.

struct MilliCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MilliSpacing.cardPadding)
            .background(MilliCardBackground(showGlow: true))
    }
}

struct MilliCardBackground: View {
    var showGlow: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)

        shape
            .fill(MilliColors.blackGlassSurface)
            .overlay {
                MilliGradients.cyanAmbient
                    .opacity(showGlow ? 1 : 0)
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .stroke(
                        showGlow ? MilliColors.precisionChromeEdge : LinearGradient(
                            colors: [MilliColors.borderSubtle, MilliColors.borderSubtle],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.72
                    )
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.clear,
                        MilliColors.glassHighlight,
                        Color.white.opacity(0.025),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.8)
                .padding(.horizontal, 18)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.clear, MilliColors.glassLowlight, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.6)
                .padding(.horizontal, 14)
                .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(0.48), radius: 14, x: 0, y: 7)
            .shadow(
                color: showGlow ? MilliColors.cyanGlow.opacity(0.035) : Color.clear,
                radius: 10,
                x: 0,
                y: -1
            )
    }
}

struct MilliCardModifier: ViewModifier {
    var padding: CGFloat = MilliSpacing.cardPadding
    var showGlow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MilliCardBackground(showGlow: showGlow))
    }
}

extension View {
    func milliCard(padding: CGFloat = MilliSpacing.cardPadding, showGlow: Bool = true) -> some View {
        modifier(MilliCardModifier(padding: padding, showGlow: showGlow))
    }
}
