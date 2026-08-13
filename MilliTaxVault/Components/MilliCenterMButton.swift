import SwiftUI

// MARK: - MilliCenterMButton — Chrome Hardware Dial
// Layered: outer metallic ring (AngularGradient multi-stop) + inner dark face
// + Milli M + top specular highlight
// Diameter: 64pt, elevated above nav, scale+haptic on tap

struct MilliCenterMButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    private let size: CGFloat = MilliLayout.mButtonSize
    
    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                // Outer chrome ring — angular multi-stop metallic
                Circle()
                    .fill(MilliGradients.chromeRing)
                    .frame(width: size, height: size)
                
                // Inner dark face
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "1A1F2E"), Color(hex: "0D1117")],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.4
                        )
                    )
                    .frame(width: size - 8, height: size - 8)
                
                // M letter — chrome gradient
                Text("M")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "C0C0C0")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Top specular highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: size - 12, height: size - 12)
                    .mask(
                        VStack {
                            Ellipse()
                                .frame(height: (size - 12) * 0.4)
                            Spacer()
                        }
                    )
                
                // Subtle cyan reflection on bottom edge
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.clear, Color.clear, MilliColors.cyan.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: size - 2, height: size - 2)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        }
        .buttonStyle(MButtonPressStyle(isPressed: $isPressed))
    }
}

// MARK: - Custom button style for press tracking
private struct MButtonPressStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, newValue in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = newValue
                }
            }
    }
}
