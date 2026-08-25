import SwiftUI

// MARK: - Milli AI Character
// Canonical Milli AI companion, rendered from the approved 3D robot asset
// (milli-ai-robot / milli-ai-robot-large imagesets — Image 31 reference).
// The vector placeholder build is retired: the single AI companion system
// is the canonical robot render, softly floating with an ambient cyan glow.

struct MilliAICharacterView: View {
    var size: CGFloat = 70
    var animated: Bool = false

    @State private var eyePulse = false
    @State private var bodyTilt: Double = -1

    private var scale: CGFloat { size / 70 }

    var body: some View {
        ZStack {
            // Ambient cyan glow beneath the robot
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(0.14))
                .frame(width: 54 * scale, height: 16 * scale)
                .blur(radius: 8 * scale)
                .offset(y: 29 * scale)

            // Canonical 3D robot render (approved asset, no redraws)
            Image("milli-ai-robot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: MilliColors.cyanGlow.opacity(eyePulse ? 0.45 : 0.22), radius: (eyePulse ? 10 : 6) * scale)
                .rotationEffect(.degrees(bodyTilt))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                eyePulse = true
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                bodyTilt = 1.2
            }
        }
    }
}

// MARK: - MilliAIOrb
// Persistent floating Milli companion. The canonical robot render is lightly
// animated so it can live at the bottom-right without appearing as a static
// image tile.

struct MilliAIOrb: View {
    @State private var floatY: CGFloat = 2
    @State private var floatX: CGFloat = -1
    @State private var tilt: Double = -1.0

    var onTap: () -> Void = {}

    private let characterSize: CGFloat = 72

    var body: some View {
        Button(action: onTap) {
            MilliAICharacterView(size: characterSize, animated: true)
                .offset(x: floatX, y: floatY)
                .rotationEffect(.degrees(tilt))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 14, height: characterSize + 14)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
                floatY = -4
                floatX = 2
                tilt = 1.1
            }
        }
    }
}
