import SwiftUI

// MARK: - MilliCard
// Premium graphite/black-glass surface shared by the whole app.

struct MilliCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MilliSpacing.cardPadding)
            .background(MilliCardBackground(showGlow: true))
    }
}

struct MilliCardBackground: View {
    var showGlow: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
            .fill(MilliColors.graphiteSurface)
            .overlay {
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .stroke(
                        showGlow ? MilliColors.cardBorderGlow : MilliColors.borderSubtle,
                        lineWidth: 0.75
                    )
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)
                .clipShape(RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous))
            }
            .shadow(color: Color.black.opacity(0.32), radius: 10, x: 0, y: 5)
    }
}

struct MilliCardModifier: ViewModifier {
    var padding: CGFloat = MilliSpacing.cardPadding
    var showGlow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(MilliCardBackground(showGlow: showGlow))
    }
}

extension View {
    func milliCard(padding: CGFloat = MilliSpacing.cardPadding, showGlow: Bool = true) -> some View {
        modifier(MilliCardModifier(padding: padding, showGlow: showGlow))
    }
}
