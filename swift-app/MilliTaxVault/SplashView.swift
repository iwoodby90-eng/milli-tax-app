import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    // Animation phases
    @State private var mTrimEnd: CGFloat = 0
    @State private var glowScale: CGFloat = 0.3
    @State private var glowOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var screenOpacity: Double = 1

    private let cyan = Color(red: 0, green: 0.706, blue: 1) // #00B4FF

    var body: some View {
        ZStack {
            // Pure black background
            Color(red: 0.031, green: 0.031, blue: 0.063) // #080810
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    // Radial glow pulse behind the M
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [cyan.opacity(0.6), cyan.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(glowScale)
                        .opacity(glowOpacity)

                    // Geometric M drawn with trim animation
                    MilliMPath()
                        .trim(from: 0, to: mTrimEnd)
                        .stroke(
                            cyan,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: cyan.opacity(0.8), radius: 12)
                        .shadow(color: cyan.opacity(0.4), radius: 6)
                        .frame(width: 80, height: 80)
                }
                .frame(height: 160)

                Spacer().frame(height: 24)

                // MILLI wordmark
                Text("MILLI")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .tracking(8)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(white: 0.78)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(wordmarkOpacity)

                Spacer().frame(height: 10)

                // Tax Vault tagline
                Text("Tax Vault")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .tracking(3)
                    .foregroundColor(Color(red: 0.545, green: 0.545, blue: 0.627)) // milliTextSecondary
                    .opacity(taglineOpacity)

                Spacer()
            }
        }
        .opacity(screenOpacity)
        .ignoresSafeArea()
        .onAppear { runSequence() }
    }

    private func runSequence() {
        // 0.3s — Begin M draw over 0.8s
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.8)) {
                mTrimEnd = 1.0
            }
        }

        // 1.1s — Glow pulse (scale 0.3→1.5, opacity 0.6→0, duration 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            glowOpacity = 0.6
            glowScale = 0.3
            withAnimation(.easeOut(duration: 0.6)) {
                glowScale = 1.5
                glowOpacity = 0
            }
        }

        // 1.7s — MILLI wordmark fades in over 0.5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            withAnimation(.easeInOut(duration: 0.5)) {
                wordmarkOpacity = 1.0
            }
        }

        // 2.2s — Tagline fades in over 0.4s
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                taglineOpacity = 1.0
            }
        }

        // 3.1s — Fade entire screen to black over 0.4s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            withAnimation(.easeInOut(duration: 0.4)) {
                screenOpacity = 0
            }
        }

        // 3.5s — Sequence complete, call onComplete
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onComplete()
        }
    }
}

// MARK: - Geometric M Path
// Two diagonal strokes forming an angular M silhouette:
// bottom-left → up-right to first peak → down to center valley → up-right to second peak → down to bottom-right

struct MilliMPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Start at bottom-left
        path.move(to: CGPoint(x: 0, y: h))
        // Up-right to first peak
        path.addLine(to: CGPoint(x: w * 0.25, y: 0))
        // Down to center valley
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
        // Up-right to second peak
        path.addLine(to: CGPoint(x: w * 0.75, y: 0))
        // Down to bottom-right
        path.addLine(to: CGPoint(x: w, y: h))

        return path
    }
}
