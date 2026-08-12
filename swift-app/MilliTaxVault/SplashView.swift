import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @State private var logoScale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            // Cinematic radial glow
            RadialGradient(
                colors: [MilliPalette.accent.opacity(0.06), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 200
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Animated M logo with chrome ring
                ZStack {
                    // Rotating outer ring (gauge-like)
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    MilliPalette.accent.opacity(0.5),
                                    MilliPalette.accent.opacity(0.0),
                                    MilliPalette.accent.opacity(0.3),
                                    MilliPalette.accent.opacity(0.0)
                                ],
                                center: .center
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(ringRotation))

                    // Chrome bezel
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [MilliPalette.chrome1, MilliPalette.chrome3, MilliPalette.chrome1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 88, height: 88)

                    // Dark face
                    Circle()
                        .fill(MilliPalette.background)
                        .frame(width: 82, height: 82)

                    // M character
                    Text("M")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MilliPalette.chrome1, MilliPalette.accent, MilliPalette.chrome1],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: MilliPalette.accent.opacity(0.5), radius: 6)
                }
                .scaleEffect(logoScale)
                .opacity(opacity)

                // Wordmark
                Text("MILLI")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(6)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color(white: 0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(opacity)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                opacity = 1.0
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                appState.bootstrap()
            }
        }
    }
}
