import SwiftUI

struct MilliAmbientBackground: View {
    var cyanOpacity: Double = 0.18
    var chromeOpacity: Double = 0.16
    var vignetteOpacity: Double = 0.5
    var topLeadingOffset: CGSize = CGSize(width: -60, height: -100)
    var bottomTrailingOffset: CGSize = CGSize(width: 80, height: 140)

    var body: some View {
        ZStack {
            Color.milliBackground
                .ignoresSafeArea()

            ZStack {
                RadialGradient(colors: [Color.milliCyan.opacity(cyanOpacity), .clear], center: .topLeading, startRadius: 0, endRadius: 520)
                    .blur(radius: 80)
                    .offset(topLeadingOffset)
                RadialGradient(colors: [Color.milliChrome3.opacity(chromeOpacity), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 620)
                    .blur(radius: 90)
                    .offset(bottomTrailingOffset)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [.clear, Color.black.opacity(vignetteOpacity)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 900
                    )
                )
                .blendMode(.multiply)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    MilliAmbientBackground()
        .preferredColorScheme(.dark)
}
