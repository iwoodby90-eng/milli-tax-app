import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Canonical Milli companion. The approved robot artwork remains the source of
// truth. The image is composited into the native surface with a soft edge mask
// so the original dark studio background never reads as a pasted rectangle.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.97
    @State private var glowOpacity: Double = 0.20

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(glowOpacity * 0.58))
                .frame(width: size * 0.70, height: size * 0.16)
                .blur(radius: max(7, size * 0.085))
                .scaleEffect(glowScale)
                .offset(y: size * 0.40)

            RadialGradient(
                colors: [
                    MilliColors.cyanGlow.opacity(glowOpacity * 0.36),
                    Color.clear
                ],
                center: .center,
                startRadius: 2,
                endRadius: size * 0.58
            )
            .frame(width: size * 1.10, height: size * 1.10)

            // Use one approved production asset at every size. The former
            // large variant was not visually identical and caused the AI
            // surface to diverge from the approved companion reference.
            Image("milli-ai-robot")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .mask {
                    RadialGradient(
                        stops: [
                            .init(color: .white, location: 0.00),
                            .init(color: .white, location: 0.62),
                            .init(color: .white.opacity(0.96), location: 0.76),
                            .init(color: .white.opacity(0.48), location: 0.91),
                            .init(color: .clear, location: 1.00)
                        ],
                        center: UnitPoint(x: 0.50, y: 0.49),
                        startRadius: 0,
                        endRadius: size * 0.72
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                }
                .offset(y: floatY)
                .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: max(5, size * 0.06), y: 2)
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }

            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                floatY = -3
                glowScale = 1.035
                glowOpacity = 0.34
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

    private let characterSize: CGFloat = 66

    var body: some View {
        Button(action: onTap) {
            MilliAICharacterView(size: characterSize, animated: true)
                .offset(y: floatY)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 6, height: characterSize + 8)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 2.9).repeatForever(autoreverses: true)) {
                floatY = -2
            }
        }
    }
}
