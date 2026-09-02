import SwiftUI

// MARK: - v1.2 Material Kit
// Three canonical card materials from the v1.2 Rebuild Spec. Depth comes from
// layered elevation (drop shadow, top-edge specular, 1px inner highlight) —
// never from outlines alone. Cyan is embedded illumination, never a wash.

enum MilliElevation {
    /// Soft ambient shadow under every raised surface.
    static let ambientShadowRadius: CGFloat = 14
    static let ambientShadowY: CGFloat = 7
    static let ambientShadowOpacity: Double = 0.48
    /// Tight contact shadow for hero surfaces.
    static let heroShadowRadius: CGFloat = 22
    static let heroShadowY: CGFloat = 10
    static let heroShadowOpacity: Double = 0.55
    /// 1px inner highlight near the top edge of every card.
    static let innerHighlightAlpha: Double = 0.045
    /// Top-edge specular line (leading → trailing falloff, top-left key light).
    static let specularAlpha: Double = 0.10
}

/// Shared surface scaffolding: shape, fill, top specular, inner highlight, shadows.
private struct MilliSurface: View {
    let radius: CGFloat
    let fill: ShapeStyle
    var borderColor: Color
    var borderWidth: CGFloat = 0.72
    var hero: Bool = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(fill)
            .overlay(
                shape.stroke(borderColor, lineWidth: borderWidth)
                    .allowsHitTesting(false)
            )
            .overlay(alignment: .top) {
                // Top-edge specular line — key light from top-left.
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: Color.white.opacity(MilliElevation.specularAlpha), location: 0.22),
                        .init(color: Color.white.opacity(MilliElevation.specularAlpha * 0.55), location: 0.6),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.8)
                .padding(.horizontal, 16)
                .allowsHitTesting(false)
            }
            .overlay(
                shape
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(MilliElevation.innerHighlightAlpha), location: 0.0),
                                .init(color: .clear, location: 0.35)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            )
            .shadow(
                color: Color.black.opacity(hero ? MilliElevation.heroShadowOpacity : MilliElevation.ambientShadowOpacity),
                radius: hero ? MilliElevation.heroShadowRadius : MilliElevation.ambientShadowRadius,
                x: 0,
                y: hero ? MilliElevation.heroShadowY : MilliElevation.ambientShadowY
            )
    }
}

// MARK: ObsidianGlassCard
/// Deepest black-glass surface for primary financial information.
struct ObsidianGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = MilliSpacing.radiusLg
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(MilliSpacing.cardPadding)
            .background(
                MilliSurface(
                    radius: cornerRadius,
                    fill: LinearGradient(
                        stops: [
                            .init(color: Color(hex: "0B1116"), location: 0.0),
                            .init(color: MilliColors.obsidian, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    borderColor: MilliColors.borderSubtle
                )
            )
    }
}

// MARK: CarbonCard
/// Low-glare supporting surface for secondary information.
struct CarbonCard<Content: View>: View {
    var cornerRadius: CGFloat = MilliSpacing.radiusLg
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(MilliSpacing.cardPadding)
            .background(
                MilliSurface(
                    radius: cornerRadius,
                    fill: LinearGradient(
                        stops: [
                            .init(color: Color(hex: "12191F"), location: 0.0),
                            .init(color: MilliColors.carbon, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    borderColor: Color.white.opacity(0.07)
                )
            )
    }
}

// MARK: ChromeHeroCard
/// Hero surface: glossier, chrome-edged, carries the screen's primary financial story.
/// Uses a 5-stop gradient (kills the degenerate two-stop hero issue) with full
/// direction data per the v1.2 component contract.
struct ChromeHeroCard<Content: View>: View {
    var cornerRadius: CGFloat = MilliSpacing.radiusXl
    @ViewBuilder var content: Content

    // 5-stop hero gradient, top-left key light → bottom-right falloff.
    static var heroGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "16222C"), location: 0.00),
                .init(color: Color(hex: "101922"), location: 0.28),
                .init(color: Color(hex: "0C1219"), location: 0.55),
                .init(color: Color(hex: "090E13"), location: 0.80),
                .init(color: Color(hex: "07090B"), location: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    MilliSurface(
                        radius: cornerRadius,
                        fill: Self.heroGradient,
                        borderColor: Color.white.opacity(0.10),
                        hero: true
                    )
                    // Restrained cyan focal edge — embedded, not floating.
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: MilliColors.cyanGlow.opacity(0.28), location: 0.0),
                                    .init(color: MilliColors.cyanGlow.opacity(0.06), location: 0.4),
                                    .init(color: .clear, location: 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.8
                        )
                        .allowsHitTesting(false)
                }
            )
    }
}

// MARK: - Convenience modifiers

extension View {
    /// Obsidian glass material.
    func obsidianGlassCard(cornerRadius: CGFloat = MilliSpacing.radiusLg) -> some View {
        ObsidianGlassCard(cornerRadius: cornerRadius) { self }
    }

    /// Carbon supporting material.
    func carbonCard(cornerRadius: CGFloat = MilliSpacing.radiusLg) -> some View {
        CarbonCard(cornerRadius: cornerRadius) { self }
    }

    /// Chrome-edged hero material.
    func chromeHeroCard(cornerRadius: CGFloat = MilliSpacing.radiusXl) -> some View {
        ChromeHeroCard(cornerRadius: cornerRadius) { self }
    }
}