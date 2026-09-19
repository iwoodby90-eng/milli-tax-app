import SwiftUI

// MARK: - MilliWordmark
// Approved brand lockup: the chrome MILLI artwork with the cyan accent on the
// M's inner diagonal. `fontSize` keeps the cap height of previous call sites.

struct MilliWordmark: View {
    var fontSize: CGFloat = 30
    var tracking: CGFloat = 1.6
    var showsTagline: Bool = false

    private var assetName: String {
        showsTagline ? "milli-wordmark-lockup" : "milli-wordmark-chrome"
    }

    private var height: CGFloat {
        showsTagline ? fontSize * 1.66 : fontSize * 1.08
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .shadow(color: MilliColors.cyanGlow.opacity(0.18), radius: fontSize * 0.22)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Milli")
    }
}

#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        VStack(spacing: 20) {
            MilliWordmark(fontSize: 52, showsTagline: true)
            MilliWordmark(fontSize: 34, tracking: 6.4)
            MilliWordmark()
            MilliWordmark(fontSize: 17, tracking: 3.8)
        }
    }
}
