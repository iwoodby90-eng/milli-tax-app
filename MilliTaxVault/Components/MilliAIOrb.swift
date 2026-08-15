import SwiftUI

// MARK: - MilliAIOrb
// Uses the approved robot artwork. The companion floats subtly above the shell and never becomes a generic chatbot icon.

struct MilliAIOrb: View {
    @State private var hovering = false
    @State private var breathing = false
    var onTap: () -> Void = {}

    private let orbSize: CGFloat = 58

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(breathing ? 0.14 : 0.08))
                    .frame(width: orbSize + 12, height: orbSize + 12)
                    .blur(radius: 9)

                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: orbSize, height: orbSize)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 8, x: 0, y: 3)
                    .offset(y: hovering ? -2 : 2)
            }
            .frame(width: orbSize + 16, height: orbSize + 16)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                hovering = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}
