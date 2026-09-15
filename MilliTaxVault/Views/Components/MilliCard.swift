import SwiftUI

// MARK: - MilliCard
// Canonical Milli surface system. Surfaces are intentionally restrained and
// filmic: layered graphite glass, polished edge light, a controlled cyan bloom,
// and deep OLED separation. Financial content remains the visual priority.

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

        ZStack {
            shape
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "12191D"), location: 0.00),
                            .init(color: Color(hex: "0B1013"), location: 0.34),
                            .init(color: Color(hex: "050708"), location: 0.72),
                            .init(color: Color(hex: "020304"), location: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Soft cinematic key light from the upper-left.
            LinearGradient(
                colors: [
                    Color.white.opacity(0.070),
                    Color.white.opacity(0.012),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.62, y: 0.52)
            )
            .clipShape(shape)

            // Restrained cyan atmosphere — never a neon outline around the card.
            RadialGradient(
                colors: [
                    MilliColors.cyanGlow.opacity(showGlow ? 0.070 : 0.018),
                    Color.clear
                ],
                center: UnitPoint(x: 0.94, y: 0.03),
                startRadius: 0,
                endRadius: 150
            )
            .clipShape(shape)

            // Lower-right graphite falloff adds physical depth.
            RadialGradient(
                colors: [Color.black.opacity(0.30), Color.clear],
                center: UnitPoint(x: 0.92, y: 0.98),
                startRadius: 0,
                endRadius: 180
            )
            .clipShape(shape)
        }
        .overlay {
            shape
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.27), location: 0.00),
                            .init(color: Color(hex: "9CA4AA").opacity(0.13), location: 0.30),
                            .init(color: MilliColors.cyanGlow.opacity(showGlow ? 0.13 : 0.045), location: 0.66),
                            .init(color: Color.white.opacity(0.025), location: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.72
                )
        }
        .overlay {
            shape
                .inset(by: 1.1)
                .stroke(Color.white.opacity(0.030), lineWidth: 0.55)
        }
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.white.opacity(0.34),
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 0.8)
            .padding(.horizontal, 18)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Color.clear, MilliColors.cyanGlow.opacity(showGlow ? 0.18 : 0.035)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 86, height: 0.7)
            .padding(.trailing, 17)
            .padding(.bottom, 1)
            .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(0.68), radius: 16, x: 0, y: 9)
        .shadow(
            color: showGlow ? MilliColors.cyanGlow.opacity(0.028) : Color.clear,
            radius: 12,
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
