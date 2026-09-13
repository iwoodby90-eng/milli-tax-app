import SwiftUI

// MARK: - Native Milli M
// Canonical transparent M. The geometry remains native SwiftUI while the material
// treatment follows the approved polished-silver mark with one Electric Cyan blade.

struct MilliMMark: View {
    var size: CGFloat = 62

    private var metalGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "FAFBFC"), location: 0.00),
                .init(color: Color(hex: "A4ABB1"), location: 0.20),
                .init(color: Color(hex: "F1F3F5"), location: 0.46),
                .init(color: Color(hex: "676E76"), location: 0.72),
                .init(color: Color(hex: "DDE1E4"), location: 1.00)
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
                                colors: [Color.white.opacity(0.96), Color(hex: "747B84"), Color.white.opacity(0.50)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(0.8, size * 0.018)
                        )
                }
                .shadow(color: .black.opacity(0.70), radius: size * 0.05, x: 0, y: size * 0.03)

            MilliMCyanBladeShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "8AF8FF"), Color(hex: "00E5FF"), Color(hex: "00E5FF")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliMCyanBladeShape()
                        .stroke(Color.white.opacity(0.30), lineWidth: max(0.5, size * 0.008))
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.70), radius: size * 0.065)

            MilliMHighlightShape()
                .stroke(Color.white.opacity(0.52), lineWidth: max(0.5, size * 0.009))
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
// Approved app-icon language: rounded black glass, subtle chrome edge and cyan
// perimeter light. Used by login/splash so the identity reads as a premium mark,
// not as a circular badge.

struct ChromeEmblemView: View {
    var size: CGFloat = 62

    var body: some View {
        let corner = max(15, size * 0.25)

        ZStack {
            RoundedRectangle(cornerRadius: corner + 5, style: .continuous)
                .fill(MilliColors.cyanGlow.opacity(0.08))
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 10)

            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "111820"), Color(hex: "05080B"), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size + 8, height: size + 8)
                .overlay {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.40), MilliColors.cyanGlow.opacity(0.55), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
                }
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: corner - 2, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 2)
                        .blur(radius: 1)
                        .padding(3)
                }
                .shadow(color: .black.opacity(0.65), radius: 10, y: 6)

            MilliMMark(size: size * 0.74)
                .shadow(color: MilliColors.cyanGlow.opacity(0.24), radius: 5)
        }
        .frame(width: size + 22, height: size + 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli")
    }
}
