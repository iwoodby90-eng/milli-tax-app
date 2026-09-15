import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Canonical Milli companion. Approved artwork remains the primary source of
// truth. The native fallback is deliberately production-grade so Milli can
// never disappear or collapse into a flat mascot if an asset fails to render.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var floatY: CGFloat = 0
    @State private var glowScale: CGFloat = 0.98
    @State private var glowOpacity: Double = 0.17

    private var assetName: String {
        size >= 58 ? "milli-ai-robot-large" : "milli-ai-robot"
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(glowOpacity * 0.82))
                .frame(width: size * 0.66, height: size * 0.09)
                .blur(radius: max(7, size * 0.066))
                .scaleEffect(glowScale)
                .offset(y: size * 0.44)

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(glowOpacity * 0.30), Color.clear],
                center: UnitPoint(x: 0.50, y: 0.46),
                startRadius: 2,
                endRadius: size * 0.59
            )
            .frame(width: size * 1.08, height: size * 1.08)
            .allowsHitTesting(false)

            CinematicMilliRobotFallback(size: size * 0.94)
                .offset(y: floatY)

            // Keep approved artwork on top whenever the raster is healthy.
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(y: floatY)
                .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: max(4, size * 0.045), y: 2)
        }
        .frame(width: size, height: size)
        .drawingGroup(opaque: false, colorMode: .extendedLinear)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }

            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                floatY = -2.8
                glowScale = 1.026
                glowOpacity = 0.28
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
                .init(color: Color(hex: "F5F7F8"), location: 0.00),
                .init(color: Color(hex: "7A838A"), location: 0.17),
                .init(color: Color(hex: "DCE1E4"), location: 0.39),
                .init(color: Color(hex: "3B4349"), location: 0.67),
                .init(color: Color(hex: "AAB2B7"), location: 1.00)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var darkMetal: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "313940"), Color(hex: "0C1114"), Color(hex: "020304")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            // Ground contact light.
            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(0.16))
                .frame(width: size * 0.48, height: size * 0.055)
                .blur(radius: size * 0.035)
                .offset(y: size * 0.43)

            // Legs and polished boots.
            HStack(spacing: size * 0.11) {
                leg
                leg
            }
            .offset(y: size * 0.31)

            // Right arm relaxed.
            robotArm(raised: false)
                .offset(x: size * 0.30, y: size * 0.07)
                .rotationEffect(.degrees(-11))

            // Left arm in the signature welcoming pose.
            robotArm(raised: true)
                .offset(x: -size * 0.29, y: size * 0.015)
                .rotationEffect(.degrees(42))

            torso
                .offset(y: size * 0.13)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: size * 0.18, height: size * 0.020)
                .shadow(color: MilliColors.cyanGlow.opacity(0.82), radius: size * 0.04)
                .offset(y: -size * 0.065)

            head
                .offset(y: -size * 0.18)
        }
        .frame(width: size, height: size)
    }

    private var torso: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .fill(darkMetal)
                .frame(width: size * 0.46, height: size * 0.35)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.58), Color(hex: "50585E"), MilliColors.cyanGlow.opacity(0.30)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(0.7, size * 0.008)
                        )
                }
                .shadow(color: .black.opacity(0.72), radius: size * 0.045, y: size * 0.022)

            RoundedRectangle(cornerRadius: size * 0.09, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "131B20"), Color(hex: "030506"), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.31, height: size * 0.24)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.09, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.22), lineWidth: max(0.5, size * 0.006))
                }

            MilliMMark(size: size * 0.18)
                .shadow(color: MilliColors.cyanGlow.opacity(0.48), radius: size * 0.025)
        }
    }

    private var head: some View {
        ZStack {
            // Cyan rim behind the helmet gives the approved edge-lit silhouette.
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .stroke(MilliColors.cyanGlow.opacity(0.44), lineWidth: max(1.0, size * 0.012))
                .frame(width: size * 0.62, height: size * 0.45)
                .blur(radius: size * 0.010)
                .shadow(color: MilliColors.cyanGlow.opacity(0.48), radius: size * 0.04)

            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(chrome)
                .frame(width: size * 0.61, height: size * 0.44)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.white.opacity(0.58), lineWidth: max(0.7, size * 0.008))
                }
                .shadow(color: .black.opacity(0.78), radius: size * 0.05, y: size * 0.025)

            RoundedRectangle(cornerRadius: size * 0.19, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "172229"), Color(hex: "040607"), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.50, height: size * 0.32)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.19, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: max(0.5, size * 0.005))
                }

            HStack(spacing: size * 0.17) {
                eye
                eye
            }

            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: size * 0.28, height: size * 0.016)
                .rotationEffect(.degrees(-8))
                .offset(x: -size * 0.06, y: -size * 0.105)

            HStack(spacing: size * 0.58) {
                ear
                ear
            }
        }
    }

    private var eye: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white, Color(hex: "9BFCFF"), MilliColors.cyanGlow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.070, height: size * 0.124)
            .shadow(color: MilliColors.cyanGlow.opacity(0.94), radius: size * 0.042)
    }

    private var ear: some View {
        ZStack {
            Circle()
                .fill(darkMetal)
                .frame(width: size * 0.13, height: size * 0.13)
                .overlay(Circle().stroke(chrome, lineWidth: max(0.8, size * 0.010)))
            Circle()
                .stroke(MilliColors.cyanGlow.opacity(0.62), lineWidth: max(0.6, size * 0.006))
                .frame(width: size * 0.082, height: size * 0.082)
        }
    }

    private var leg: some View {
        VStack(spacing: -size * 0.012) {
            Capsule()
                .fill(chrome)
                .frame(width: size * 0.13, height: size * 0.22)
                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: max(0.5, size * 0.005)))
            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .fill(darkMetal)
                .frame(width: size * 0.19, height: size * 0.078)
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                        .stroke(Color.white.opacity(0.32), lineWidth: max(0.5, size * 0.005))
                }
        }
    }

    private func robotArm(raised: Bool) -> some View {
        VStack(spacing: -size * 0.016) {
            Circle()
                .fill(chrome)
                .frame(width: size * 0.11, height: size * 0.11)
                .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: max(0.5, size * 0.005)))

            Capsule()
                .fill(darkMetal)
                .frame(width: size * 0.105, height: size * 0.16)
                .overlay(Capsule().stroke(Color.white.opacity(0.24), lineWidth: max(0.5, size * 0.005)))

            Circle()
                .fill(chrome)
                .frame(width: size * 0.092, height: size * 0.092)

            Capsule()
                .fill(darkMetal)
                .frame(width: size * 0.086, height: size * (raised ? 0.12 : 0.10))
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: max(0.5, size * 0.005)))

            Circle()
                .fill(chrome)
                .frame(width: size * 0.082, height: size * 0.082)
        }
    }
}

// MARK: - MilliAIOrb
// Contextual launcher remains intentionally small. Full-body Milli belongs in
// dedicated AI and insight surfaces; the launcher should never compete with
// financial information or navigation hardware.

struct MilliAIOrb: View {
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "151D22"), Color(hex: "05080A"), .black],
                            center: UnitPoint(x: 0.38, y: 0.26),
                            startRadius: 1,
                            endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.36), MilliColors.cyanGlow.opacity(0.38), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.7
                            )
                    }
                    .shadow(color: .black.opacity(0.66), radius: 7, y: 4)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.10), radius: 8)

                MilliAICharacterView(size: 37, animated: true)
                    .frame(width: 37, height: 37)
                    .clipShape(Circle())
            }
            .frame(width: 48, height: 48)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Milli AI")
    }
}
