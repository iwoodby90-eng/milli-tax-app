import SwiftUI
import UIKit

// MARK: - Milli AI Character
// Vector-built transparent companion. No bitmap plate or opaque background is used.
// The approved native Milli M is rendered on the character's chest.

struct MilliAICharacterView: View {
    var size: CGFloat = 70
    var animated: Bool = false

    @State private var eyePulse = false
    @State private var bodyTilt: Double = -1
    @State private var haloRotation: Double = 0
    @State private var haloScale: CGFloat = 0.96

    private var scale: CGFloat { size / 70 }

    var body: some View {
        ZStack {
            // Ambient animated energy field behind Milli AI. It is transparent,
            // so the dashboard remains visible through the effect.
            if animated {
                Circle()
                    .trim(from: 0.08, to: 0.82)
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, MilliColors.cyanGlow.opacity(0.45), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 1.2 * scale, lineCap: .round)
                    )
                    .frame(width: 60 * scale, height: 60 * scale)
                    .rotationEffect(.degrees(haloRotation))
                    .scaleEffect(haloScale)
                    .blur(radius: 0.35 * scale)

                Circle()
                    .trim(from: 0.18, to: 0.72)
                    .stroke(MilliColors.deepCyan.opacity(0.30), lineWidth: 0.8 * scale)
                    .frame(width: 68 * scale, height: 68 * scale)
                    .rotationEffect(.degrees(-haloRotation * 0.72))
                    .scaleEffect(1.02)
            }

            Ellipse()
                .fill(MilliColors.cyanGlow.opacity(0.11))
                .frame(width: 54 * scale, height: 18 * scale)
                .blur(radius: 8 * scale)
                .offset(y: 29 * scale)

            VStack(spacing: -2 * scale) {
                head
                    .zIndex(2)
                torso
                    .zIndex(1)
            }
            .rotationEffect(.degrees(bodyTilt))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli AI")
        .onAppear {
            guard animated, !UIAccessibility.isReduceMotionEnabled else { return }

            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                eyePulse = true
            }

            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                bodyTilt = 1.2
                haloScale = 1.04
            }

            withAnimation(.linear(duration: 9.5).repeatForever(autoreverses: false)) {
                haloRotation = 360
            }
        }
    }

    private var head: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cardBackground, MilliColors.cardBackground, Color.black],
                        center: UnitPoint(x: 0.48, y: 0.38),
                        startRadius: 1,
                        endRadius: 25 * scale
                    )
                )
                .frame(width: 37 * scale, height: 37 * scale)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeDeep],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.4 * scale
                        )
                }
                .overlay {
                    Circle()
                        .stroke(MilliColors.cyanGlow.opacity(0.45), lineWidth: 0.7 * scale)
                        .padding(3 * scale)
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 7 * scale)

            HStack(spacing: 7 * scale) {
                eye
                eye
            }
            .offset(y: -1 * scale)

            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.22))
                .frame(width: 14 * scale, height: 1.2 * scale)
                .offset(y: 9 * scale)

            earPod
                .offset(x: -21 * scale, y: 0)
            earPod
                .offset(x: 21 * scale, y: 0)
        }
    }

    private var eye: some View {
        Circle()
            .fill(MilliColors.cyanGlow)
            .frame(width: 4.6 * scale, height: 4.6 * scale)
            .shadow(
                color: MilliColors.cyanGlow.opacity(eyePulse ? 0.95 : 0.55),
                radius: (eyePulse ? 4.2 : 2.2) * scale
            )
    }

    private var earPod: some View {
        Capsule(style: .continuous)
            .fill(chromeGradient)
            .frame(width: 5.5 * scale, height: 14 * scale)
            .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 2.5 * scale)
    }

    private var torso: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(chromeGradient)
                .frame(width: 7 * scale, height: 24 * scale)
                .rotationEffect(.degrees(23))
                .offset(x: -20 * scale, y: 2 * scale)

            Capsule(style: .continuous)
                .fill(chromeGradient)
                .frame(width: 7 * scale, height: 24 * scale)
                .rotationEffect(.degrees(-23))
                .offset(x: 20 * scale, y: 2 * scale)

            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [MilliColors.cardBackground, MilliColors.cardBackground, MilliColors.cardBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 34 * scale, height: 28 * scale)
                .overlay {
                    RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                        .stroke(chromeGradient, lineWidth: 1.4 * scale)
                }
                .overlay(alignment: .top) {
                    Capsule(style: .continuous)
                        .fill(MilliColors.cyanGlow.opacity(0.55))
                        .frame(width: 17 * scale, height: 1.3 * scale)
                        .padding(.top, 4 * scale)
                }

            MilliMMark(size: 15 * scale)
                .shadow(color: MilliColors.cyanGlow.opacity(0.25), radius: 2 * scale)
                .offset(y: 1 * scale)

            HStack(spacing: 9 * scale) {
                Capsule(style: .continuous)
                    .fill(chromeGradient)
                    .frame(width: 9 * scale, height: 4 * scale)
                Capsule(style: .continuous)
                    .fill(chromeGradient)
                    .frame(width: 9 * scale, height: 4 * scale)
            }
            .offset(y: 17 * scale)
        }
        .frame(width: 58 * scale, height: 32 * scale)
    }

    private var chromeGradient: LinearGradient {
        LinearGradient(
            colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - MilliAIOrb
// Persistent floating Milli companion. The character is transparent and animated
// so it can live at the bottom-right without appearing as a square image tile.

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
            if !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
                    floatY = -4
                    floatX = 2
                    tilt = 1.1
                }
            }
        }
    }
}
