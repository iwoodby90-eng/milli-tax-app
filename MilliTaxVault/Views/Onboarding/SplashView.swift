import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @State private var emblemScale: CGFloat = 0.82
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MilliColors.cardBackground, MilliColors.obsidian, MilliColors.cardBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                ChromeEmblemView(size: 136)
                    .scaleEffect(emblemScale)

                VStack(spacing: 14) {
                    Image("milli_wordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 290)
                        .accessibilityHidden(true)

                    // Brand rule: the tagline is not screen copy (30-screen spec,
                    // conflict #3). The cyan light seam below remains the brand moment.
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, MilliColors.cyanGlow, Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 96, height: 1.5)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.45), radius: 4)
                }
                .opacity(contentOpacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("MILLI. Money, Made Intelligent.")

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55)) {
                emblemScale = 1
            }

            withAnimation(.easeInOut(duration: 0.5).delay(0.28)) {
                contentOpacity = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
