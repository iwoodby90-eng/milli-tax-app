import SwiftUI

// MARK: - MilliCard — Standard card container with dark glass surface + cyan border glow

struct MilliCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MilliSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                            .stroke(MilliColors.cardBorderGlow, lineWidth: 1)
                    )
            )
    }
}

// MARK: - View Modifier variant

struct MilliCardModifier: ViewModifier {
    var padding: CGFloat = MilliSpacing.cardPadding
    var showGlow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                            .stroke(
                                showGlow ? MilliColors.cardBorderGlow : MilliColors.border,
                                lineWidth: showGlow ? 1 : 0.5
                            )
                    )
            )
    }
}

extension View {
    func milliCard(padding: CGFloat = MilliSpacing.cardPadding, showGlow: Bool = true) -> some View {
        modifier(MilliCardModifier(padding: padding, showGlow: showGlow))
    }
}
