import SwiftUI

// MARK: - Milli AI Character
// Vector-built transparent companion. No bitmap plate or opaque background is used.
// The approved MilliMLogo asset is the only M rendered on the character.

struct MilliAICharacterView: View {
    var size: CGFloat = 70
    var animated: Bool = false

    @State private var eyePulse = false
    @State private var bodyTilt: Double = -1

    private var scale: CGFloat { size / 70 }

    var body: some View {
        ZStack {
            // Soft ambient glow only — there is intentionally no card/background shape.
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
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                eyePulse = true
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                bodyTilt = 1.2
            }
        }
    }

    private var head: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "13232C"), Color(hex: "05090C"), Color.black],
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

            // Headphone-style ear pods
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
            .fill(
                LinearGradient(
                    colors: [MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 5.5 * scale, height: 14 * scale)
            .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 2.5 * scale)
    }

    private var torso: some View {
        ZStack {
            // Arms
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

            // Body shell
            RoundedRectangle(cornerRadius: 10 * scale, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "27333A"), Color(hex: "0B1014"), Color(hex: "171E23")],
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

            // Approved M on chest
            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 15 * scale, height: 15 * scale)
                .blendMode(.screen)
                .clipShape(Circle())
                .shadow(color: MilliColors.cyanGlow.opacity(0.25), radius: 2 * scale)
                .offset(y: 1 * scale)

            // Feet
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
// Persistent floating Milli companion. The character is transparent and lightly animated
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
            withAnimation(.easeInOut(duration: 2.7).repeatForever(autoreverses: true)) {
                floatY = -4
                floatX = 2
                tilt = 1.1
            }
        }
    }
}
