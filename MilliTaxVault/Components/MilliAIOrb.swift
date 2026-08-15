import SwiftUI

// MARK: - MilliAIOrb — Floating AI robot companion (bottom-right, every page)
// A stylized glowing robotic head that pulses with cyan energy.

struct MilliAIOrb: View {
    @State private var isPulsing = false
    @State private var isHovering = false
    var onTap: () -> Void = {}

    private let orbSize: CGFloat = 48

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow backdrop
                Circle()
                    .fill(MilliColors.cyan.opacity(0.15))
                    .frame(width: orbSize + 12, height: orbSize + 12)
                    .blur(radius: 8)
                    .scaleEffect(isPulsing ? 1.1 : 0.9)

                // Robot body
                ZStack {
                    // Head
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1A2E4A"), Color(hex: "0D1B2E")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: orbSize - 8, height: orbSize - 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(MilliColors.cyan.opacity(0.5), lineWidth: 1)
                        )

                    // Eyes
                    HStack(spacing: 8) {
                        eyeDot
                        eyeDot
                    }
                    .offset(y: -2)

                    // Antenna
                    VStack(spacing: 0) {
                        Circle()
                            .fill(MilliColors.cyan)
                            .frame(width: 5, height: 5)
                            .shadow(color: MilliColors.cyan, radius: 3)
                        Rectangle()
                            .fill(MilliColors.chromeMid)
                            .frame(width: 1.5, height: 6)
                    }
                    .offset(y: -(orbSize / 2 - 6))
                }
            }
            .frame(width: orbSize + 16, height: orbSize + 16)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private var eyeDot: some View {
        Circle()
            .fill(MilliColors.cyan)
            .frame(width: 7, height: 7)
            .shadow(color: MilliColors.cyan.opacity(0.8), radius: 3)
    }
}
