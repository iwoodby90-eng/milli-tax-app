import SwiftUI

// MARK: - MilliCard — Standard card container with dark glass surface

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
                            .stroke(MilliColors.border, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - View Modifier variant

struct MilliCardModifier: ViewModifier {
    var padding: CGFloat = MilliSpacing.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                            .stroke(MilliColors.border, lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func milliCard(padding: CGFloat = MilliSpacing.cardPadding) -> some View {
        modifier(MilliCardModifier(padding: padding))
    }
}
