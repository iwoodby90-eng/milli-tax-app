import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Canonical companion renderer. The approved robot artwork is the visual source of
// truth; SwiftUI supplies only restrained ambient motion/light so the character
// never drifts into a simplified/cartoon reconstruction.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var haloScale: CGFloat = 0.96
    @State private var haloOpacity: Double = 0.20

    private var assetName: String {
        size >= 110 ? "milli-ai-robot-large" : "milli-ai-robot"
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(0.12))
                .frame(width: size * 0.72, height: size * 0.18)
                .blur(radius: max(5, size * 0.07))
                .scaleEffect(haloScale)
                .offset(y: size * 0.37)

            Circle()
                .stroke(MilliColors.cyanGlow.opacity(haloOpacity), lineWidth: max(0.7, size * 0.008))
                .frame(width: size * 0.84, height: size * 0.84)
                .blur(radius: 0.25)

            Image(assetName)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: floatY)
                .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: max(4, size * 0.055), y: 2)
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }

            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                floatY = -3.5
                haloScale = 1.04
                haloOpacity = 0.36
            }
        }
    }
}

// MARK: - MilliAIOrb
// Persistent companion. Intentionally smaller and visually lighter than the
// navigation dial so it reads as an assistant, not a competing primary control.

struct MilliAIOrb: View {
    @State private var floatY: CGFloat = 1

    var onTap: () -> Void = {}

    private let characterSize: CGFloat = 76

    var body: some View {
        Button(action: onTap) {
            MilliAICharacterView(size: characterSize, animated: true)
                .offset(y: floatY)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 8, height: characterSize + 8)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) {
                floatY = -2
            }
        }
    }
}
