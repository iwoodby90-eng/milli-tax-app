import SwiftUI

// MARK: - MilliCard Container View
// Use as a container wrapper: MilliCard { content }
// For the modifier version, use .milliCard() from MilliTheme.swift

struct MilliCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(MilliSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(LinearGradient(
                        colors: [Color(hex: "10171D"), Color(hex: "0C1217")],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliRadius.card)
                            .stroke(MilliColor.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            )
    }
}
