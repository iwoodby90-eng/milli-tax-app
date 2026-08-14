import SwiftUI

struct MilliAICompanion: View {
    @State private var floating = false
    @State private var showSheet = false
    
    var body: some View {
        Button(action: { showSheet = true }) {
            ZStack {
                // Ambient glow — soft radial, no hard border
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MilliColors.cyan.opacity(0.18),
                                MilliColors.cyan.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 36
                        )
                    )
                    .frame(width: 68, height: 68)
                
                // Brand AI robot asset — no ring, no label
                Image("MilliAIOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
            }
        }
        .buttonStyle(.plain)
        .offset(y: floating ? -3 : 0)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
        .padding(.bottom, 80)
        .padding(.trailing, 16)
        .onAppear { floating = true }
        .sheet(isPresented: $showSheet) {
            ZStack {
                MilliColors.obsidian.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Milli AI")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Your financial AI assistant")
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// Extension to apply Milli AI companion as overlay
extension View {
    func withMilliAI() -> some View {
        self.overlay(alignment: .bottomTrailing) {
            MilliAICompanion()
        }
    }
}

#Preview {
    ZStack {
        MilliColors.obsidian.ignoresSafeArea()
        Text("Screen Content")
            .foregroundStyle(.white)
    }
    .withMilliAI()
}
