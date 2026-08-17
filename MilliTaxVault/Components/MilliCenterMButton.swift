import SwiftUI

// MARK: - MilliCenterMButton — 3D Chrome Hardware Dial with Segmented Cyan Ring
// Visual spec: 1954 Bel Air dashboard gauge / hardware dial
// Layers (outside-in):
//   1. Segmented cyan illuminated tick ring (48 segments, glowing)
//   2. Outer chrome bezel (angular gradient, multi-stop metallic)
//   3. Mid chrome groove (dark recessed channel)
//   4. Inner dark face (radial gradient, deep obsidian)
//   5. Approved Milli M artwork, optically composited onto the face
//   6. Top specular highlight crescent (white→clear)
//   7. Bottom cyan ambient reflection
// Diameter: 78pt (within 74–82pt spec)
// Interaction: scale-down + haptic impact on press

struct MilliCenterMButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var glowPulse = false

    private let outerSize: CGFloat = 78
    private let grooveInset: CGFloat = 7
    private let innerFaceInset: CGFloat = 10

    var body: some View {
        Button(action: action) {
            ZStack {
                segmentedCyanRing

                Circle()
                    .fill(MilliGradients.chromeRing)
                    .frame(width: outerSize, height: outerSize)
                    .shadow(color: .black.opacity(0.62), radius: 7, x: 0, y: 5)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "0A0C0F"), Color(hex: "15181C")],
                            center: .center,
                            startRadius: 0,
                            endRadius: (outerSize - grooveInset * 2) / 2
                        )
                    )
                    .frame(width: outerSize - grooveInset * 2, height: outerSize - grooveInset * 2)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.72), lineWidth: 0.8)
                    }

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "1A1F2E"), Color(hex: "0D1117"), Color(hex: "07090B")],
                            center: .center,
                            startRadius: 0,
                            endRadius: (outerSize - innerFaceInset * 2) / 2
                        )
                    )
                    .frame(width: outerSize - innerFaceInset * 2, height: outerSize - innerFaceInset * 2)
                    .overlay {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color(hex: "4A4F55").opacity(0.66),
                                        Color(hex: "A8AFB4").opacity(0.34),
                                        Color(hex: "4A4F55").opacity(0.62),
                                        Color(hex: "8D9397").opacity(0.32),
                                        Color(hex: "4A4F55").opacity(0.66)
                                    ],
                                    center: .center
                                ),
                                lineWidth: 1
                            )
                    }

                // The approved logo PNG contains a dark source plate. Screen compositing
                // optically drops that black plate into the black-glass dial while retaining
                // the metallic/cyan M itself, avoiding a visible square inside the round control.
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .blendMode(.screen)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.16), radius: 3)
                    .accessibilityHidden(true)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: outerSize - innerFaceInset * 2 - 4, height: outerSize - innerFaceInset * 2 - 4)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse()
                                .frame(height: (outerSize - innerFaceInset * 2) * 0.34)
                            Spacer()
                        }
                    )
                    .allowsHitTesting(false)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, Color.clear, MilliColors.cyan.opacity(0.27), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: outerSize - 1, height: outerSize - 1)
                    .allowsHitTesting(false)
            }
            .scaleEffect(isPressed ? 0.94 : 1)
            .animation(.easeInOut(duration: 0.08), value: isPressed)
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: isPressed)
        }
        .buttonStyle(MDialPressStyle(isPressed: $isPressed))
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private var segmentedCyanRing: some View {
        let tickCount = 48
        let ringRadius: CGFloat = (outerSize / 2) + 5
        let tickLength: CGFloat = 4
        let tickWidth: CGFloat = 1.5

        return ZStack {
            ForEach(0..<tickCount, id: \.self) { index in
                let angle = (Double(index) / Double(tickCount)) * 360

                Capsule()
                    .fill(MilliColors.cyan.opacity(glowPulse ? 0.82 : 0.52))
                    .frame(width: tickWidth, height: tickLength)
                    .offset(y: -ringRadius)
                    .rotationEffect(.degrees(angle))
                    .shadow(color: MilliColors.cyan.opacity(glowPulse ? 0.52 : 0.22), radius: 2)
            }
        }
        .frame(width: outerSize + 14, height: outerSize + 14)
    }
}

private struct MDialPressStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B")
        MilliCenterMButton(action: {})
    }
}
