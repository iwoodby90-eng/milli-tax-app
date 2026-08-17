import SwiftUI

// MARK: - ChromeEmblemView
// Canonical Milli identity renderer. Never redraw the approved M with typography or SF Symbols.
// The MilliMLogo asset is the single source of truth for the M geometry/material treatment.

struct ChromeEmblemView: View {
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.16), Color.black.opacity(0.72), Color.clear],
                        center: .center,
                        startRadius: size * 0.14,
                        endRadius: size * 0.72
                    )
                )
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 3)

            Circle()
                .fill(Color.black.opacity(0.66))
                .frame(width: size + 4, height: size + 4)
                .overlay {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.24), MilliColors.cyanGlow.opacity(0.22), Color.white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }

            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .blendMode(.screen)
                .clipShape(Circle())
                .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: 5)
                .accessibilityHidden(true)
        }
        .frame(width: size + 20, height: size + 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli")
    }
}
