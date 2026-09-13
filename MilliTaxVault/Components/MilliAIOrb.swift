import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Canonical Milli companion. The approved transparent robot artwork is the source
// of truth. No masking, blending workaround, or opaque plate is allowed around it.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.98
    @State private var glowOpacity: Double = 0.18

    private var assetName: String {
        size >= 120 ? "milli-ai-robot-large" : "milli-ai-robot"
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(glowOpacity * 0.68))
                .frame(width: size * 0.64, height: size * 0.12)
                .blur(radius: max(7, size * 0.075))
                .scaleEffect(glowScale)
                .offset(y: size * 0.43)

            RadialGradient(
                colors: [
                    MilliColors.cyanGlow.opacity(glowOpacity * 0.28),
                    Color.clear
                ],
                center: UnitPoint(x: 0.50, y: 0.52),
                startRadius: 2,
                endRadius: size * 0.60
            )
            .frame(width: size * 1.08, height: size * 1.08)
            .allowsHitTesting(false)

            Image(assetName)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: floatY)
                .shadow(
                    color: MilliColors.cyanGlow.opacity(0.20),
                    radius: max(5, size * 0.055),
                    y: 2
                )
        }
        .frame(width: size, height: size)
        .drawingGroup(opaque: false, colorMode: .extendedLinear)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }

            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                floatY = -3
                glowScale = 1.03
                glowOpacity = 0.31
            }
        }
    }
}

// MARK: - MilliAIOrb
// Compact contextual launcher. It intentionally stays visually subordinate to
// the canonical center-M navigation control.

struct MilliAIOrb: View {
    @State private var floatY: CGFloat = 1

    var onTap: () -> Void = {}

    private let characterSize: CGFloat = 64

    var body: some View {
        Button(action: onTap) {
            MilliAICharacterView(size: characterSize, animated: true)
                .offset(y: floatY)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 8, height: characterSize + 10)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) {
                floatY = -2
            }
        }
    }
}
