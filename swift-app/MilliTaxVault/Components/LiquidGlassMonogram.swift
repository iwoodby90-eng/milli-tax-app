import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LiquidGlassMonogram: View {
    var size: CGFloat = 120
    var glowColor: Color = .milliCyan

    // If you add a vector PDF named "MilliMonogram" to Assets, it will be used automatically.
    // Otherwise we fall back to a stylized "M".
    @ViewBuilder
    private var monogram: some View {
        if UIImage(named: "MilliMonogram") != nil {
            Image("MilliMonogram")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Text("M")
                .font(.system(size: size, weight: .bold, design: .rounded))
        }
    }

    var body: some View {
        let highlight = LinearGradient(
            colors: [Color.white.opacity(0.0), Color.white.opacity(0.9), Color.white.opacity(0.0)],
            startPoint: .top,
            endPoint: .bottom
        )

        ZStack {
            // Liquid glass core (material masked to monogram)
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    monogram
                )

            // Specular sweep highlight
            highlight
                .rotationEffect(.degrees(24))
                .offset(x: -size * 0.8)
                .frame(width: size * 2.2, height: size * 2.2)
                .mask(monogram)
                .blendMode(.screen)
                .animation(.linear(duration: 1.8).repeatForever(autoreverses: false), value: UUID())

            // Subtle inner chrome gradient
            LinearGradient(
                colors: [Color.milliChrome3.opacity(0.7), Color.milliChrome1.opacity(0.9), .white.opacity(0.8), Color.milliChrome2.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .mask(monogram)
            .opacity(0.65)

            // Outer rim glow
            monogram
                .foregroundColor(.clear)
                .glow(color: glowColor, radius: 26)
                .blendMode(.plusLighter)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Milli Monogram")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LiquidGlassMonogram(size: 140)
    }
}
