import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Native SwiftUI reconstruction of the approved glossy black/chrome Milli AI
// reference: rounded visor head, cyan illuminated eyes/rim, articulated metallic
// body, and the canonical transparent Milli M on the chest. No opaque image plate.

struct MilliAICharacterView: View {
    var size: CGFloat = 88
    var animated: Bool = false

    @State private var eyePulse = false
    @State private var floatOffset: CGFloat = 1.5
    @State private var haloRotation: Double = 0
    @State private var armLift: Double = -4

    private var scale: CGFloat { size / 100 }

    var body: some View {
        ZStack {
            if animated {
                Circle()
                    .trim(from: 0.05, to: 0.78)
                    .stroke(
                        AngularGradient(
                            colors: [Color.clear, MilliColors.cyanGlow.opacity(0.55), Color.clear],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 1.2 * scale, lineCap: .round)
                    )
                    .frame(width: 92 * scale, height: 92 * scale)
                    .rotationEffect(.degrees(haloRotation))
                    .blur(radius: 0.25 * scale)

                Circle()
                    .stroke(MilliColors.deepCyan.opacity(0.18), lineWidth: 0.8 * scale)
                    .frame(width: 82 * scale, height: 82 * scale)
            }

            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(0.18))
                .frame(width: 60 * scale, height: 13 * scale)
                .blur(radius: 7 * scale)
                .offset(y: 43 * scale)

            VStack(spacing: -1 * scale) {
                headAssembly
                    .zIndex(4)
                bodyAssembly
                    .zIndex(2)
            }
            .offset(y: floatOffset)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }

            withAnimation(.easeInOut(duration: 1.55).repeatForever(autoreverses: true)) {
                eyePulse = true
            }

            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                floatOffset = -2.5
                armLift = 3
            }

            withAnimation(.linear(duration: 10.5).repeatForever(autoreverses: false)) {
                haloRotation = 360
            }
        }
    }

    // MARK: Head

    private var headAssembly: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                .fill(chromeGradient)
                .frame(width: 58 * scale, height: 45 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 20 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8 * scale)
                }
                .shadow(color: .black.opacity(0.72), radius: 5 * scale, y: 4 * scale)

            RoundedRectangle(cornerRadius: 17 * scale, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "13232A"), Color(hex: "05090C"), Color.black],
                        center: UnitPoint(x: 0.44, y: 0.30),
                        startRadius: 1,
                        endRadius: 32 * scale
                    )
                )
                .frame(width: 52 * scale, height: 39 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 17 * scale, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.72), lineWidth: 1.15 * scale)
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.34), radius: 6 * scale)

            // Gloss reflection from the approved visor reference.
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.38), Color.white.opacity(0.02)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 25 * scale, height: 7 * scale)
                .rotationEffect(.degrees(-12))
                .offset(x: -8 * scale, y: -12 * scale)
                .blur(radius: 0.45 * scale)

            HStack(spacing: 15 * scale) {
                eye
                eye
            }
            .offset(y: -1 * scale)

            earPod
                .offset(x: -32 * scale)
            earPod
                .offset(x: 32 * scale)
        }
        .frame(width: 70 * scale, height: 47 * scale)
    }

    private var eye: some View {
        Capsule(style: .continuous)
            .fill(Color(hex: "8AF8FF"))
            .frame(width: 5.2 * scale, height: 10.5 * scale)
            .overlay {
                Capsule(style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(0.88))
                    .padding(0.7 * scale)
            }
            .shadow(
                color: MilliColors.cyanGlow.opacity(eyePulse ? 0.95 : 0.58),
                radius: (eyePulse ? 5.5 : 3.0) * scale
            )
    }

    private var earPod: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(chromeGradient)
                .frame(width: 8 * scale, height: 21 * scale)
            Capsule(style: .continuous)
                .fill(Color(hex: "091015"))
                .frame(width: 4.5 * scale, height: 15 * scale)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.42), lineWidth: 0.6 * scale)
                }
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 3 * scale)
    }

    // MARK: Body

    private var bodyAssembly: some View {
        ZStack {
            neck
                .offset(y: -23 * scale)

            leftArm
                .offset(x: -27 * scale, y: -4 * scale)
                .rotationEffect(.degrees(armLift), anchor: .topTrailing)

            rightArm
                .offset(x: 27 * scale, y: -4 * scale)
                .rotationEffect(.degrees(-armLift), anchor: .topLeading)

            torso
                .zIndex(3)

            leftLeg
                .offset(x: -11 * scale, y: 29 * scale)
            rightLeg
                .offset(x: 11 * scale, y: 29 * scale)
        }
        .frame(width: 72 * scale, height: 54 * scale)
    }

    private var neck: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(chromeGradient)
                .frame(width: 17 * scale, height: 10 * scale)
            Capsule(style: .continuous)
                .fill(MilliColors.cyanGlow.opacity(0.38))
                .frame(width: 12 * scale, height: 2.2 * scale)
                .offset(y: -2 * scale)
        }
    }

    private var torso: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14 * scale, style: .continuous)
                .fill(chromeGradient)
                .frame(width: 42 * scale, height: 38 * scale)
                .shadow(color: .black.opacity(0.72), radius: 4 * scale, y: 3 * scale)

            RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "151D22"), Color(hex: "070B0E"), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36 * scale, height: 32 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                        .stroke(Color.white.opacity(0.16), lineWidth: 0.6 * scale)
                }

            RoundedRectangle(cornerRadius: 7 * scale, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .frame(width: 25 * scale, height: 21 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 7 * scale, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.20), lineWidth: 0.6 * scale)
                }

            MilliMMark(size: 19 * scale)
                .shadow(color: MilliColors.cyanGlow.opacity(0.42), radius: 3 * scale)

            Capsule(style: .continuous)
                .fill(MilliColors.cyanGlow.opacity(0.48))
                .frame(width: 19 * scale, height: 1.5 * scale)
                .offset(y: -13 * scale)
        }
    }

    private var leftArm: some View {
        arm(isLeft: true)
    }

    private var rightArm: some View {
        arm(isLeft: false)
    }

    private func arm(isLeft: Bool) -> some View {
        VStack(spacing: -1 * scale) {
            Capsule(style: .continuous)
                .fill(chromeGradient)
                .frame(width: 9 * scale, height: 22 * scale)
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 0.5 * scale)
                }

            Circle()
                .fill(chromeGradient)
                .frame(width: 8 * scale, height: 8 * scale)

            RoundedRectangle(cornerRadius: 3 * scale)
                .fill(Color(hex: "11171B"))
                .frame(width: 8 * scale, height: 6 * scale)
        }
        .rotationEffect(.degrees(isLeft ? 13 : -13))
    }

    private var leftLeg: some View {
        leg
    }

    private var rightLeg: some View {
        leg
    }

    private var leg: some View {
        VStack(spacing: -1 * scale) {
            Capsule(style: .continuous)
                .fill(chromeGradient)
                .frame(width: 10 * scale, height: 18 * scale)
            RoundedRectangle(cornerRadius: 4 * scale)
                .fill(
                    LinearGradient(
                        colors: [MilliColors.chromeWhite, MilliColors.chromeMid, Color(hex: "11171B")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 15 * scale, height: 7 * scale)
        }
    }

    private var chromeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "F4F7F9"), location: 0.0),
                .init(color: Color(hex: "838B94"), location: 0.30),
                .init(color: Color(hex: "D8DDE2"), location: 0.58),
                .init(color: Color(hex: "424951"), location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - MilliAIOrb
// Persistent floating companion sized to read as the approved full-body robot,
// not as a tiny generic orb.

struct MilliAIOrb: View {
    @State private var floatY: CGFloat = 2
    @State private var floatX: CGFloat = -1
    @State private var tilt: Double = -0.8

    var onTap: () -> Void = {}

    private let characterSize: CGFloat = 94

    var body: some View {
        Button(action: onTap) {
            MilliAICharacterView(size: characterSize, animated: true)
                .offset(x: floatX, y: floatY)
                .rotationEffect(.degrees(tilt))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: characterSize + 12, height: characterSize + 12)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            if !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    floatY = -4
                    floatX = 2
                    tilt = 0.9
                }
            }
        }
    }
}
