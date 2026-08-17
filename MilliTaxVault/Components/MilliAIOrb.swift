import SwiftUI

// MARK: - MilliAIOrb
// Uses the approved robot artwork. The companion floats subtly above the shell and never becomes a generic chatbot icon.

struct MilliAIOrb: View {
    @State private var hovering = false
    @State private var breathing = false
    var onTap: () -> Void = {}

    private let orbSize: CGFloat = 54

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(breathing ? 0.13 : 0.07))
                    .frame(width: orbSize + 14, height: orbSize + 14)
                    .blur(radius: 10)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "101A22"), MilliColors.blackGlass],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: orbSize * 0.62
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [MilliColors.silverBright.opacity(0.42), MilliColors.cyanGlow.opacity(0.34), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }
                    .shadow(color: .black.opacity(0.65), radius: 9, y: 5)

                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFill()
                    .frame(width: orbSize - 5, height: orbSize - 5)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 0.7)
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.26), radius: 7, x: 0, y: 2)
                    .offset(y: hovering ? -1 : 1)
            }
            .frame(width: orbSize + 18, height: orbSize + 18)
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
