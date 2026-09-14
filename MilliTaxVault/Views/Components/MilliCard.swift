import SwiftUI

// MARK: - MilliCard
// Canonical Milli surface system. Every reusable card now shares the same
// premium black-glass material language: near-black graphite, a machined silver
// edge, restrained Electric Cyan atmosphere, controlled specular light and deep
// OLED separation. The treatment is intentionally quiet so financial content
// remains dominant.

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
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "121B20"), location: 0.00),
                        .init(color: Color(hex: "0A0F12"), location: 0.42),
                        .init(color: Color(hex: "050708"), location: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RadialGradient(
                    colors: [
                        MilliColors.cyanGlow.opacity(showGlow ? 0.060 : 0.020),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.86, y: 0.06),
                    startRadius: 0,
                    endRadius: 150
                )
                .clipShape(shape)
                .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
                                Color(hex: "8B949C").opacity(0.12),
                                MilliColors.cyanGlow.opacity(showGlow ? 0.12 : 0.04),
                                Color.white.opacity(0.025)
                            ],
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
                        Color.white.opacity(0.30),
                        Color.white.opacity(0.045),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.7)
                .padding(.horizontal, 17)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomTrailing) {
                LinearGradient(
                    colors: [Color.clear, MilliColors.cyanGlow.opacity(showGlow ? 0.18 : 0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 88, height: 0.7)
                .padding(.trailing, 16)
                .padding(.bottom, 1)
                .allowsHitTesting(false)
            }
            .shadow(color: Color.black.opacity(0.58), radius: 14, x: 0, y: 8)
            .shadow(
                color: showGlow ? MilliColors.cyanGlow.opacity(0.022) : Color.clear,
                radius: 9,
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
