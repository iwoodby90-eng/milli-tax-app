import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Canonical Milli companion. Approved artwork remains the primary visual source
// of truth. A native cinematic fallback sits underneath the asset so Milli can
// never disappear because of a bad/transparent raster export. The fallback is
// deliberately premium: polished metal, black glass face, cyan optics, chrome
// limbs, chest mark and grounded light — never a flat mascot or sticker.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.98
    @State private var glowOpacity: Double = 0.16

    private var assetName: String {
        size >= 58 ? "milli-ai-robot-large" : "milli-ai-robot"
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(glowOpacity * 0.82))
                .frame(width: size * 0.64, height: size * 0.10)
                .blur(radius: max(7, size * 0.065))
                .scaleEffect(glowScale)
                .offset(y: size * 0.43)

            RadialGradient(
                colors: [
                    MilliColors.cyanGlow.opacity(glowOpacity * 0.30),
                    Color.clear
                ],
                center: UnitPoint(x: 0.50, y: 0.46),
                startRadius: 2,
                endRadius: size * 0.58
            )
            .frame(width: size * 1.08, height: size * 1.08)
            .allowsHitTesting(false)

            // Production-safe fallback. This guarantees a visible, on-brand
            // Milli even when a raster asset is malformed or unexpectedly blank.
            CinematicMilliRobotFallback(size: size * 0.93)
                .offset(y: floatY)

            // Approved artwork stays on top when the asset is healthy.
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: floatY)
                .shadow(
                    color: MilliColors.cyanGlow.opacity(0.18),
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
                glowOpacity = 0.27
            }
        }
    }
}

// MARK: - Native cinematic fallback

private struct CinematicMilliRobotFallback: View {
    let size: CGFloat

    private var chrome: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "F4F7F8"), location: 0.00),
                .init(color: Color(hex: "7B858C"), location: 0.18),
                .init(color: Color(hex: "DCE2E5"), location: 0.42),
                .init(color: Color(hex: "3A4248"), location: 0.68),
                .init(color: Color(hex: "AEB6BB"), location: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var darkMetal: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "2A3238"), Color(hex: "090D10"), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Legs
            HStack(spacing: size * 0.12) {
                leg
                leg
            }
            .offset(y: size * 0.31)

            // Arms
            HStack(spacing: size * 0.55) {
                arm(rotation: 16)
                arm(rotation: -16)
            }
            .offset(y: size * 0.07)

            // Torso
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                    .fill(darkMetal)
                    .frame(width: size * 0.46, height: size * 0.36)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.62), Color(hex: "515A60"), MilliColors.cyanGlow.opacity(0.42)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: max(0.65, size * 0.009)
                            )
                    }

                RoundedRectangle(cornerRadius: size * 0.09, style: .continuous)
                    .fill(Color(hex: "05080A"))
                    .frame(width: size * 0.31, height: size * 0.25)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.09, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.25), lineWidth: max(0.5, size * 0.006))
                    }

                MilliMMark(size: size * 0.17)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.46), radius: size * 0.025)
            }
            .offset(y: size * 0.14)

            // Neck glow
            Capsule()
                .fill(MilliColors.cyanGlow)
                .frame(width: size * 0.20, height: size * 0.025)
                .shadow(color: MilliColors.cyanGlow.opacity(0.72), radius: size * 0.045)
                .offset(y: -size * 0.075)

            // Head shell
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                    .fill(chrome)
                    .frame(width: size * 0.60, height: size * 0.43)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                            .stroke(Color.white.opacity(0.58), lineWidth: max(0.7, size * 0.008))
                    }
                    .shadow(color: Color.black.opacity(0.72), radius: size * 0.045, y: size * 0.02)

                RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "10181D"), Color(hex: "020304"), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.49, height: size * 0.31)
                    .overlay {
                        RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                            .stroke(MilliColors.cyanGlow.opacity(0.20), lineWidth: max(0.5, size * 0.005))
                    }

                HStack(spacing: size * 0.17) {
                    eye
                    eye
                }

                // Specular visor highlight
                Capsule()
                    .fill(Color.white.opacity(0.17))
                    .frame(width: size * 0.27, height: size * 0.018)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -size * 0.06, y: -size * 0.10)
            }
            .offset(y: -size * 0.17)

            // Ear pods
            HStack(spacing: size * 0.56) {
                ear
                ear
            }
            .offset(y: -size * 0.15)
        }
        .frame(width: size, height: size)
    }

    private var eye: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white, Color(hex: "8AF8FF"), MilliColors.cyanGlow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.072, height: size * 0.125)
            .shadow(color: MilliColors.cyanGlow.opacity(0.88), radius: size * 0.04)
    }

    private var ear: some View {
        Circle()
            .fill(darkMetal)
            .frame(width: size * 0.13, height: size * 0.13)
            .overlay(Circle().stroke(chrome, lineWidth: max(0.8, size * 0.01)))
            .overlay {
                Circle()
                    .stroke(MilliColors.cyanGlow.opacity(0.55), lineWidth: max(0.5, size * 0.006))
                    .padding(size * 0.025)
            }
    }

    private var leg: some View {
        VStack(spacing: -size * 0.012) {
            Capsule()
                .fill(chrome)
                .frame(width: size * 0.13, height: size * 0.23)
            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .fill(darkMetal)
                .frame(width: size * 0.18, height: size * 0.075)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                        .stroke(Color.white.opacity(0.34), lineWidth: max(0.5, size * 0.005))
                }
        }
    }

    private func arm(rotation: Double) -> some View {
        VStack(spacing: -size * 0.018) {
            Circle()
                .fill(chrome)
                .frame(width: size * 0.11, height: size * 0.11)
            Capsule()
                .fill(darkMetal)
                .frame(width: size * 0.105, height: size * 0.23)
                .overlay(Capsule().stroke(Color.white.opacity(0.26), lineWidth: max(0.5, size * 0.005)))
            Circle()
                .fill(chrome)
                .frame(width: size * 0.095, height: size * 0.095)
        }
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - MilliAIOrb
// Contextual launcher used only on secondary utility surfaces. Primary cinematic
// screens already contain integrated Milli AI treatments and must remain clean.

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
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.40), MilliColors.cyanGlow.opacity(0.42), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }
                    .shadow(color: .black.opacity(0.62), radius: 8, y: 4)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.12), radius: 9)

                MilliAICharacterView(size: 46, animated: true)
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
            }
            .frame(width: 56, height: 56)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Milli AI")
    }
}
