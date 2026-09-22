import SwiftUI

// MARK: - MilliCard
// Reference-locked black-glass surface: deep obsidian body, machined silver edge,
// subtle cyan atmosphere, and a narrow top specular highlight.

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
                        .init(color: Color(hex: "151A1F"), location: 0.00),
                        .init(color: Color(hex: "0E1318"), location: 0.34),
                        .init(color: Color(hex: "090D11"), location: 0.76),
                        .init(color: Color(hex: "06080A"), location: 1.00)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                if showGlow {
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.085), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 170
                    )
                    .clipShape(shape)
                    .allowsHitTesting(false)
                }
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.38), location: 0.00),
                                .init(color: MilliColors.chromeMid.opacity(0.17), location: 0.30),
                                .init(color: MilliColors.cyanGlow.opacity(showGlow ? 0.27 : 0.10), location: 0.62),
                                .init(color: Color.white.opacity(0.08), location: 1.00)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.28),
                        Color.white.opacity(0.055),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 0.9)
                .padding(.horizontal, 18)
            }
            .shadow(color: Color.black.opacity(0.62), radius: 18, x: 0, y: 9)
            .shadow(color: showGlow ? MilliColors.cyanGlow.opacity(0.06) : .clear, radius: 14, x: 0, y: -2)
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
