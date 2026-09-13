import SwiftUI

// MARK: - MilliWordmark
// Canonical wordmark: polished silver letters with one Electric Cyan blade in the
// M. The brand mark stays transparent and native so it never reads as a pasted
// rectangular image on dark surfaces.

struct MilliWordmark: View {
    var fontSize: CGFloat = 30
    var tracking: CGFloat = 1.6

    private var chromeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "FFFFFF"), location: 0.00),
                .init(color: Color(hex: "9CA4AA"), location: 0.22),
                .init(color: Color(hex: "F5F7F8"), location: 0.48),
                .init(color: Color(hex: "697077"), location: 0.72),
                .init(color: Color(hex: "D9DDE0"), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var approvedMAccent: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "8AF8FF"), Color(hex: "00E5FF"), Color(hex: "00E5FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(Color.black.opacity(0.88))
                .offset(y: max(0.7, fontSize * 0.035))

            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(chromeGradient)
                .overlay {
                    Text("MILLI")
                        .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                        .tracking(tracking)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white.opacity(0.48), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .mask(
                            Text("MILLI")
                                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                                .tracking(tracking)
                        )
                }

            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(approvedMAccent)
                .mask(MInnerDiagonalMask())
        }
        .shadow(color: Color.black.opacity(0.45), radius: 2.5, y: 2)
        .shadow(color: MilliColors.cyanGlow.opacity(0.08), radius: 4)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Milli")
    }
}

private struct MInnerDiagonalMask: Shape {
    func path(in rect: CGRect) -> Path {
        let mWidth = rect.width * 0.22
        let centerX = mWidth * 0.5
        let diagonalHalfWidth = mWidth * 0.10

        var path = Path()
        path.move(to: CGPoint(x: centerX - diagonalHalfWidth * 0.3, y: rect.minY))
        path.addLine(to: CGPoint(x: centerX + diagonalHalfWidth * 1.6, y: rect.minY))
        path.addLine(to: CGPoint(x: centerX + diagonalHalfWidth * 0.4, y: rect.maxY * 0.7))
        path.addLine(to: CGPoint(x: centerX - diagonalHalfWidth * 1.0, y: rect.maxY * 0.7))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        VStack(spacing: 20) {
            MilliWordmark(fontSize: 34, tracking: 6.4)
            MilliWordmark()
            MilliWordmark(fontSize: 17, tracking: 3.8)
        }
    }
}
