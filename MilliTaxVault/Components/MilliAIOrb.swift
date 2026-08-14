import SwiftUI

// MARK: - MilliAIOrb — Floating AI Companion
// Uses the official Milli AI robot brand asset.
// Floating animation + ambient cyan glow. No border, no ring, no label.
// Bottom-right on every screen.

struct MilliAIOrb: View {
    @State private var floating = false
    @State private var glowing = false
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Ambient glow — soft radial, no hard edge
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MilliColors.cyan.opacity(glowing ? 0.22 : 0.08),
                                MilliColors.cyan.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 38
                        )
                    )
                    .frame(width: 72, height: 72)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowing)
                
                // Brand AI robot asset — no border, no background shape
                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
        .offset(y: floating ? -3 : 0)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
        .onAppear {
            floating = true
            glowing = true
        }
    }
}

#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        MilliAIOrb()
    }
}
