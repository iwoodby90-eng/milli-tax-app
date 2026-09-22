import SwiftUI

// MARK: - MilliWordmark
// Canonical production wordmark. The asset is the approved chrome treatment used
// throughout the visual reference boards; do not recreate it with plain text.

struct MilliWordmark: View {
    var fontSize: CGFloat = 30
    var tracking: CGFloat = 1.6

    var body: some View {
        Image("milli_wordmark")
            .resizable()
            .scaledToFit()
            .frame(height: max(18, fontSize * 1.18))
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("Milli")
    }
}

#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        VStack(spacing: 24) {
            MilliWordmark(fontSize: 38)
            MilliWordmark(fontSize: 28)
            MilliWordmark(fontSize: 18)
        }
        .padding()
    }
}
