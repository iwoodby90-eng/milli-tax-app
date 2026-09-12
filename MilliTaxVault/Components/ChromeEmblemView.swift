import SwiftUI

// MARK: - Native Milli M
// The Milli M is rendered entirely in SwiftUI so it always has a transparent
// background and blends naturally into every surface. Do not replace this with
// a screenshot or bitmap logo plate.

struct MilliMMark: View {
    var size: CGFloat = 62

    private var metalGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "F7F9FB"), location: 0.00),
                .init(color: Color(hex: "9FA6AE"), location: 0.22),
                .init(color: Color(hex: "EEF1F4"), location: 0.47),
                .init(color: Color(hex: "666D76"), location: 0.72),
                .init(color: Color(hex: "D8DCE1"), location: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            MilliMShape()
                .fill(metalGradient)
                .overlay {
                    MilliMShape()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color(hex: "747B84"), Color.white.opacity(0.52)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(0.8, size * 0.018)
                        )
                }
                .shadow(color: .black.opacity(0.72), radius: size * 0.055, x: 0, y: size * 0.035)

            // Signature electric-cyan inner blade from the approved M reference.
            MilliMCyanBladeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "00F0FF"), Color(hex: "00B4C2"), Color(hex: "007B89")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliMCyanBladeShape()
                        .stroke(Color.white.opacity(0.34), lineWidth: max(0.5, size * 0.008))
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.72), radius: size * 0.07)

            // Small specular pass gives the mark dimensionality without adding
            // any opaque plate behind it.
            MilliMHighlightShape()
                .stroke(Color.white.opacity(0.55), lineWidth: max(0.5, size * 0.009))
                .blur(radius: 0.15)
        }
        .frame(width: size, height: size)
        .drawingGroup()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli")
    }
}

private struct MilliMShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        var p = Path()
        p.move(to: CGPoint(x: x + w * 0.08, y: y + h * 0.88))
        p.addLine(to: CGPoint(x: x + w * 0.08, y: y + h * 0.13))
        p.addLine(to: CGPoint(x: x + w * 0.25, y: y + h * 0.13))
        p.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.48))
        p.addLine(to: CGPoint(x: x + w * 0.75, y: y + h * 0.13))
        p.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.13))
        p.addLine(to: CGPoint(x: x + w * 0.92, y: y + h * 0.88))
        p.addLine(to: CGPoint(x: x + w * 0.76, y: y + h * 0.88))
        p.addLine(to: CGPoint(x: x + w * 0.76, y: y + h * 0.39))
        p.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.69))
        p.addLine(to: CGPoint(x: x + w * 0.24, y: y + h * 0.39))
        p.addLine(to: CGPoint(x: x + w * 0.24, y: y + h * 0.88))
        p.closeSubpath()
        return p
    }
}

private struct MilliMCyanBladeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        var p = Path()
        p.move(to: CGPoint(x: x + w * 0.665, y: y + h * 0.535))
        p.addLine(to: CGPoint(x: x + w * 0.758, y: y + h * 0.405))
        p.addLine(to: CGPoint(x: x + w * 0.758, y: y + h * 0.77))
        p.addLine(to: CGPoint(x: x + w * 0.665, y: y + h * 0.90))
        p.closeSubpath()
        return p
    }
}

private struct MilliMHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height

        var p = Path()
        p.move(to: CGPoint(x: x + w * 0.11, y: y + h * 0.18))
        p.addLine(to: CGPoint(x: x + w * 0.24, y: y + h * 0.18))
        p.addLine(to: CGPoint(x: x + w * 0.50, y: y + h * 0.53))
        p.addLine(to: CGPoint(x: x + w * 0.74, y: y + h * 0.18))
        return p
    }
}

// MARK: - ChromeEmblemView
// Glass/chrome presentation used by login and splash screens. The glass is
// intentional UI chrome; the M itself remains fully transparent and native.

struct ChromeEmblemView: View {
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.16), Color.black.opacity(0.72), Color.clear],
                        center: .center,
                        startRadius: size * 0.14,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 3)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.08), Color(hex: "071015").opacity(0.92), Color.black.opacity(0.94)],
                        center: UnitPoint(x: 0.42, y: 0.32),
                        startRadius: 1,
                        endRadius: size * 0.62
                    )
                )
                .frame(width: size + 4, height: size + 4)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.32), MilliColors.cyanGlow.opacity(0.52), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
                }

            MilliMMark(size: size * 0.72)
                .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 6)
        }
        .frame(width: size + 20, height: size + 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli")
    }
}
