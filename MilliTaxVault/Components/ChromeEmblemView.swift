import SwiftUI

// MARK: - ChromeEmblemView
// Canonical Milli identity renderer. Never redraw the approved M with typography or SF Symbols.
// The MilliMLogo asset is the single source of truth for the M geometry/material treatment.

struct ChromeEmblemView: View {
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.20), Color.clear],
                        center: .center,
                        startRadius: size * 0.30,
                        endRadius: size * 0.78
                    )
                )
                .frame(width: size + 18, height: size + 18)
                .blur(radius: 5)

            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
        .frame(width: size + 18, height: size + 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Milli")
    }
}
