import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Canonical Milli companion. The approved transparent robot artwork is the
// visual source of truth. SwiftUI adds only environmental light and restrained
// motion; it never redraws, masks, or places the character on an opaque plate.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.98
    @State private var glowOpacity: Double = 0.16

    private var assetName: String {
        // Use the high-detail master for nearly every visible product surface.
        // The compact asset is reserved for very small inline placements.
        size >= 58 ? "milli-ai-robot-large" : "milli-ai-robot"
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(glowOpacity * 0.72))
                .frame(width: size * 0.58, height: size * 0.09)
                .blur(radius: max(7, size * 0.065))
                .scaleEffect(glowScale)
                .offset(y: size * 0.43)

            RadialGradient(
                colors: [
                    MilliColors.cyanGlow.opacity(glowOpacity * 0.24),
                    Color.clear
                ],
                center: UnitPoint(x: 0.50, y: 0.48),
                startRadius: 2,
                endRadius: size * 0.56
            )
            .frame(width: size * 1.02, height: size * 1.02)
            .allowsHitTesting(false)

            Image(assetName)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: floatY)
                .shadow(
                    color: MilliColors.cyanGlow.opacity(0.16),
                    radius: max(4, size * 0.045),
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

            withAnimation(.easeInOut(duration: 3.1).repeatForever(autoreverses: true)) {
                floatY = -2.5
                glowScale = 1.025
                glowOpacity = 0.26
            }
        }
    }
}

// MARK: - MilliAIOrb
// Contextual launcher used by the app shell. It is intentionally compact so the
// navigation and financial content retain visual priority. Full-body Milli is
// reserved for AI, onboarding, and insight surfaces.

struct MilliAIOrb: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "101A20"), Color(hex: "05080A"), .black],
                            center: UnitPoint(x: 0.38, y: 0.26),
                            startRadius: 1,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.34), MilliColors.cyanGlow.opacity(0.34), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }
                    .shadow(color: .black.opacity(0.62), radius: 8, y: 4)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.10), radius: 8)

                MilliAICharacterView(size: 45, animated: true)
                    .frame(width: 43, height: 43)
                    .clipShape(Circle())
            }
            .frame(width: 54, height: 54)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Milli AI")
    }
}
