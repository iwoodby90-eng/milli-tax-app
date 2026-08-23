import SwiftUI

// MARK: - MilliWordmark
// Canonical wordmark per Ian's spec: chrome/silver 3D letters
// with a cyan accent ONLY on the M's inner diagonal.
// Other letters (I, L, L, I) are pure chrome gradient.

struct MilliWordmark: View {
    var fontSize: CGFloat = 30
    var tracking: CGFloat = 1.6

    // Chrome gradient applied to all characters
    private var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeWhite],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            // Base chrome text
            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(chromeGradient)

            // Cyan accent overlay — clipped to M's inner diagonal
            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliColors.deepCyan.opacity(0.85), MilliColors.cyan.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    MInnerDiagonalMask()
                )
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.14), radius: 4)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Milli")
    }
}

// Custom shape that covers only the M's inner diagonal stroke region.
// The M occupies approximately the first 22% of the "MILLI" text width;
// the inner diagonal is the center V-notch of the character.
private struct MInnerDiagonalMask: Shape {
    func path(in rect: CGRect) -> Path {
        let mWidth = rect.width * 0.22
        let centerX = mWidth * 0.5
        let diagonalHalfWidth = mWidth * 0.10

        var path = Path()
        // Triangle covering the inner V of the M (left diagonal stroke)
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
