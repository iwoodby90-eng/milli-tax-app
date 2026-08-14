import SwiftUI

// MARK: - MilliCenterMButton — 3D Chrome Hardware Dial with Segmented Cyan Ring
// Visual spec: 1954 Bel Air dashboard gauge / hardware dial
// Layers (outside-in):
//   1. Segmented cyan illuminated tick ring (48 segments, glowing)
//   2. Outer chrome bezel (angular gradient, multi-stop metallic)
//   3. Mid chrome groove (dark recessed channel)
//   4. Inner dark face (radial gradient, deep obsidian)
//   5. Chrome "M" letterform (linear gradient top-to-bottom, SF Pro Display Bold)
//   6. Top specular highlight crescent (white→clear)
//   7. Bottom cyan ambient reflection
// Diameter: 78pt (within 74–82pt spec)
// Interaction: scale-down + Core Haptics impact on press

struct MilliCenterMButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var glowPulse = false
    
    // Spec: 74–82pt range
    private let outerSize: CGFloat = 78
    private let chromeBezelInset: CGFloat = 3
    private let grooveInset: CGFloat = 7
    private let innerFaceInset: CGFloat = 10
    
    var body: some View {
        Button(action: { action() }) {
            ZStack {
                // Layer 1: Segmented cyan illuminated tick ring
                segmentedCyanRing
                
                // Layer 2: Outer chrome bezel — angular metallic gradient
                Circle()
                    .fill(MilliGradients.chromeRing)
                    .frame(width: outerSize, height: outerSize)
                    .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 4)
                
                // Layer 3: Recessed groove channel
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
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                    )
                
                // Layer 4: Inner dark face
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
                    .overlay(
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [
                                        Color(hex: "4A4F55").opacity(0.6),
                                        Color(hex: "8D9397").opacity(0.3),
                                        Color(hex: "4A4F55").opacity(0.6),
                                        Color(hex: "8D9397").opacity(0.3),
                                        Color(hex: "4A4F55").opacity(0.6)
                                    ],
                                    center: .center
                                ),
                                lineWidth: 1.0
                            )
                    )
                
                // Layer 5: Chrome "M" — SF Pro Display Bold, gradient fill
                Text("M")
                    .font(.system(size: 26, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "D4D8DC"), Color(hex: "A0A8B0")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
                
                // Layer 6: Top specular highlight crescent
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: outerSize - innerFaceInset * 2 - 4, height: outerSize - innerFaceInset * 2 - 4)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse()
                                .frame(height: (outerSize - innerFaceInset * 2) * 0.35)
                            Spacer()
                        }
                    )
                
                // Layer 7: Bottom cyan ambient reflection
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, Color.clear, MilliColors.cyan.opacity(0.25), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: outerSize - 1, height: outerSize - 1)
            }
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: isPressed)
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: isPressed)
        }
        .buttonStyle(MDialPressStyle(isPressed: $isPressed))
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    // MARK: - Segmented Cyan Ring
    // 48 tick marks arranged radially outside the chrome bezel
    private var segmentedCyanRing: some View {
        let tickCount = 48
        let ringRadius: CGFloat = (outerSize / 2) + 5
        let tickLength: CGFloat = 4
        let tickWidth: CGFloat = 1.5
        
        return ZStack {
            ForEach(0..<tickCount, id: \.self) { index in
                let angle = (Double(index) / Double(tickCount)) * 360.0
                let radians = angle * .pi / 180.0
                
                Capsule()
                    .fill(MilliColors.cyan.opacity(glowPulse ? 0.8 : 0.5))
                    .frame(width: tickWidth, height: tickLength)
                    .offset(y: -ringRadius)
                    .rotationEffect(.degrees(angle))
                    .shadow(color: MilliColors.cyan.opacity(glowPulse ? 0.5 : 0.2), radius: 2, x: 0, y: 0)
            }
        }
        .frame(width: outerSize + 14, height: outerSize + 14)
    }
}

// MARK: - Custom press style for dial interaction
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
