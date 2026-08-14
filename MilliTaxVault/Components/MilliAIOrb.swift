import SwiftUI

// MARK: - MilliAIOrb — Floating AI Companion
// Uses the official Milli AI robot brand asset.
// Floating animation + breathing cyan glow. Bottom-right on every screen.

struct MilliAIOrb: View {
    @State private var floating = false
    @State private var glowing = false
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Breathing glow ring
                Circle()
                    .fill(MilliColors.cyan.opacity(glowing ? 0.18 : 0.06))
                    .frame(width: 68, height: 68)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowing)
                
                // Outer chrome ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: "8D9397"),
                                Color(hex: "D4D8DC"),
                                Color(hex: "8D9397"),
                                Color(hex: "4A4F55"),
                                Color(hex: "8D9397")
                            ],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: MilliColors.cyan.opacity(0.4), radius: 6)
                
                // Dark face background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "0D1117"), Color(hex: "07090B")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 26
                        )
                    )
                    .frame(width: 52, height: 52)
                
                // Brand AI robot asset
                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
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
