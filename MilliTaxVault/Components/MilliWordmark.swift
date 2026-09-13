import SwiftUI

// MARK: - MilliWordmark
// Canonical wordmark: polished silver letters with one Electric Cyan structural
// blade inside the M. The cyan is intentionally narrow and confined to the
// descending inner-right stroke shown in the approved brand boards.

struct MilliWordmark: View {
    var fontSize: CGFloat = 30
    var tracking: CGFloat = 1.6

    private var chromeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "FFFFFF"), location: 0.00),
                .init(color: Color(hex: "A7AEB4"), location: 0.18),
                .init(color: Color(hex: "F7F8F9"), location: 0.43),
                .init(color: Color(hex: "666E75"), location: 0.70),
                .init(color: Color(hex: "DDE1E4"), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var approvedMAccent: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "A5FBFF"), location: 0.00),
                .init(color: MilliColors.cyanGlow, location: 0.34),
                .init(color: MilliColors.deepCyan, location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            Text("MILLI")
                .font(.custom("Sora-Bold", size: fontSize, relativeTo: .title))
                .tracking(tracking)
                .foregroundStyle(Color.black.opacity(0.90))
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
                                colors: [Color.white.opacity(0.52), Color.clear],
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
                .mask(ApprovedMBladeMask())
        }
        .shadow(color: Color.black.opacity(0.46), radius: 2.5, y: 2)
        .shadow(color: MilliColors.cyanGlow.opacity(0.075), radius: 4)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Milli")
    }
}

private struct ApprovedMBladeMask: Shape {
    func path(in rect: CGRect) -> Path {
        let mWidth = rect.width * 0.22
        let valleyX = mWidth * 0.54
        let rightInnerX = mWidth * 0.70

        var path = Path()
        path.move(to: CGPoint(x: valleyX, y: rect.height * 0.34))
        path.addLine(to: CGPoint(x: rightInnerX, y: rect.height * 0.22))
        path.addLine(to: CGPoint(x: rightInnerX, y: rect.height * 0.98))
        path.addLine(to: CGPoint(x: valleyX + mWidth * 0.035, y: rect.height * 0.84))
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
