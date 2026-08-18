import SwiftUI

// MARK: - MilliAIOrb
// Persistent floating Milli companion. The approved character artwork is rendered
// directly with no circular plate, card, badge, or artificial background.

struct MilliAIOrb: View {
    @State private var floatY: CGFloat = 2
    @State private var floatX: CGFloat = -1
    @State private var tilt: Double = -1.0
    @State private var glowPulse = false

    var onTap: () -> Void = {}

    private let characterSize: CGFloat = 68

    var body: some View {
        Button(action: onTap) {
            Image("milli-ai-robot-large")
                .resizable()
                .scaledToFit()
                .frame(width: characterSize, height: characterSize)
                .offset(x: floatX, y: floatY)
                .rotationEffect(.degrees(tilt))
                .shadow(
                    color: MilliColors.cyanGlow.opacity(glowPulse ? 0.33 : 0.18),
                    radius: glowPulse ? 9 : 5,
                    x: 0,
                    y: 3
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 10, height: characterSize + 10)
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
