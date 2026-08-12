import SwiftUI

// MARK: - Pressable Scale (micro interaction)

struct PressableScale: ViewModifier {
    @GestureState private var isPressed = false
    var scale: CGFloat = 0.98

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in
                        state = true
                    }
            )
    }
}

extension View {
    func pressableScale(_ scale: CGFloat = 0.98) -> some View { self.modifier(PressableScale(scale: scale)) }
}

// MARK: - Shimmer Sweep (micro interaction)

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1.0
    var speed: Double = 1.6
    var opacity: Double = 0.35
    var angle: Double = 20
    var bandSize: CGFloat = 0.3

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    let w = proxy.size.width
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(opacity),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: w * bandSize)
                    .rotationEffect(.degrees(angle))
                    .offset(x: phase * (w * 1.8))
                    .blendMode(.screen)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer(speed: Double = 1.6, opacity: Double = 0.35, angle: Double = 20, bandSize: CGFloat = 0.3) -> some View {
        self.modifier(Shimmer(speed: speed, opacity: opacity, angle: angle, bandSize: bandSize))
    }
}
