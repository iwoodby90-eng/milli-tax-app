import SwiftUI

struct MilliCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MilliColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MilliColors.cardStroke, lineWidth: 1)
            )
            .shadow(color: MilliColors.cardShadow, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Card Modifier (alternative usage)

struct MilliCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(MilliColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MilliColors.cardStroke, lineWidth: 1)
            )
            .shadow(color: MilliColors.cardShadow, radius: 12, x: 0, y: 4)
    }
}

extension View {
    func milliCard() -> some View {
        modifier(MilliCardModifier())
    }
}
