import SwiftUI

// MARK: - SplashView
// Launch identity: chrome wordmark, tagline hairline and the Milli companion
// rising out of the obsidian canvas, matching the launch reference.

struct SplashView: View {
    var onComplete: () -> Void

    @State private var wordmarkOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var companionOffset: CGFloat = 26
    @State private var companionOpacity: Double = 0
    @State private var hairlineWidth: CGFloat = 0

    var body: some View {
        ZStack {
            MilliAmbientBackground()

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                MilliWordmark(fontSize: 52, tracking: 9)
                    .opacity(wordmarkOpacity)

                VStack(spacing: 10) {
                    Text("Money, Made Intelligent.")
                        .font(.custom("Inter-Medium", size: 14, relativeTo: .subheadline))
                        .tracking(2.2)
                        .foregroundStyle(MilliColors.silver)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, MilliColors.cyanGlow, Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: hairlineWidth, height: 1.5)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 5)
                }
                .opacity(taglineOpacity)

                Image("milli-ai-robot-large")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 320)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.26), radius: 28)
                    .offset(y: companionOffset)
                    .opacity(companionOpacity)
                    .accessibilityHidden(true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("MILLI. Money, Made Intelligent.")
        }
        .onAppear(perform: animateIn)
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.55)) {
            wordmarkOpacity = 1
        }

        withAnimation(.easeInOut(duration: 0.5).delay(0.26)) {
            taglineOpacity = 1
            hairlineWidth = 180
        }

        withAnimation(.easeOut(duration: 0.7).delay(0.34)) {
            companionOffset = 0
            companionOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) {
            onComplete()
        }
    }
}

#Preview {
    SplashView(onComplete: {})
}
