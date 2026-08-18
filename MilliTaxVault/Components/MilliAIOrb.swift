import SwiftUI

// MARK: - MilliAIOrb
// Persistent floating Milli companion. The source art is rendered optically over
// the interface with its black plate removed by screen compositing so Milli reads
// as a free-floating character rather than a square image tile.

struct MilliAIOrb: View {
    @State private var floatY: CGFloat = 2
    @State private var floatX: CGFloat = -1
    @State private var tilt: Double = -1.0
    @State private var glowPulse = false

    var onTap: () -> Void = {}

    private let characterSize: CGFloat = 64

    var body: some View {
        Button(action: onTap) {
            Image("milli-ai-robot-large")
                .resizable()
                .scaledToFit()
                .frame(width: characterSize, height: characterSize)
                .compositingGroup()
                .blendMode(.screen)
                .offset(x: floatX, y: floatY)
                .rotationEffect(.degrees(tilt))
                .shadow(
                    color: MilliColors.cyanGlow.opacity(glowPulse ? 0.30 : 0.16),
                    radius: glowPulse ? 8 : 4,
                    x: 0,
                    y: 3
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 12, height: characterSize + 12)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                floatY = -3
                floatX = 2
                tilt = 1.4
                glowPulse = true
            }
        }
    }
}
