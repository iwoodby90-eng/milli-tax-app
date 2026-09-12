import SwiftUI

// MARK: - MilliWordmark
// Canonical wordmark: chrome/silver 3D letters with the approved Electric Cyan
// accent ONLY on the M's inner diagonal. I, L, L, I remain pure chrome.

struct MilliWordmark: View {
    var fontSize: CGFloat = 30
    var tracking: CGFloat = 1.6

    private var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeWhite],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var approvedMAccent: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "8AF8FF"),
                Color(hex: "00E5FF"),
                Color(hex: "00B4C2")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(chromeGradient)

            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(approvedMAccent)
                .mask(MInnerDiagonalMask())
        }
        .shadow(color: Color(hex: "00E5FF").opacity(0.12), radius: 4)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Milli")
    }
}

// Custom shape covering only the M's inner diagonal stroke region.
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
