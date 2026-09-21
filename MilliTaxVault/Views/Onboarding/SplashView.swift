import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @State private var contentScale: CGFloat = 0.94
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            MilliColors.obsidian.ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.10), .clear],
                center: UnitPoint(x: 0.5, y: 0.56),
                startRadius: 0,
                endRadius: 310
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.white.opacity(0.018), .clear, Color.black.opacity(0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                MilliWordmark(fontSize: 54)
                    .frame(maxWidth: 300)

                Text("Money, Made Intelligent.")
                    .font(.custom("Inter-Medium", size: 15, relativeTo: .subheadline))
                    .tracking(1.25)
                    .foregroundStyle(MilliColors.silver)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.clear, MilliColors.cyanGlow, .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 138, height: 1.2)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.50), radius: 5)

                Image("milli-ai-robot-large")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 285, maxHeight: 360)
                    .padding(.top, 20)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 20, y: 12)

                Spacer()
            }
            .padding(.horizontal, 30)
            .scaleEffect(contentScale)
            .opacity(contentOpacity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("MILLI. Money, Made Intelligent.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) {
                contentScale = 1
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
        .preferredColorScheme(.dark)
}
