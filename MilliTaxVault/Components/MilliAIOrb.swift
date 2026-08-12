import SwiftUI

struct MilliAIOrb: View {
    @State private var floating = false
    @State private var glowing = false
    var onTap: () -> Void = {}
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Breathing glow
                Circle()
                    .fill(MilliColor.cyan.opacity(glowing ? 0.2 : 0.08))
                    .frame(width: 68, height: 68)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowing)
                
                // Main orb
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "0A1628"), Color(hex: "05080F")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .stroke(MilliColor.cyan.opacity(0.6), lineWidth: 1.5)
                            .shadow(color: MilliColor.cyan, radius: 6)
                    )
                
                // AI icon
                VStack(spacing: 0) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(MilliColor.cyan)
                }
            }
        }
        .offset(y: floating ? -3 : 0)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
        .onAppear {
            floating = true
            glowing = true
        }
    }
}
