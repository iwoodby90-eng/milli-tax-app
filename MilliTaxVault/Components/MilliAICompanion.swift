import SwiftUI

struct MilliAICompanion: View {
    @State private var floating = false
    @State private var showSheet = false
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: { showSheet = true }) {
                ZStack {
                    // Main orb
                    Circle()
                        .fill(Color(hex: "1A1F2E"))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "00E5FF").opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color(hex: "00E5FF").opacity(0.2), radius: 8)
                    
                    // Two cyan glowing eyes
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color(hex: "00E5FF"))
                            .frame(width: 8, height: 8)
                            .blur(radius: 2)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "00E5FF"))
                                    .frame(width: 5, height: 5)
                            )
                        Circle()
                            .fill(Color(hex: "00E5FF"))
                            .frame(width: 8, height: 8)
                            .blur(radius: 2)
                            .overlay(
                                Circle()
                                    .fill(Color(hex: "00E5FF"))
                                    .frame(width: 5, height: 5)
                            )
                    }
                }
            }
            .offset(y: floating ? -3 : 0)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
            
            // Label pill
            Text("Milli AI")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(hex: "1A1F2E"))
                )
        }
        .padding(.bottom, 80)
        .padding(.trailing, 16)
        .onAppear { floating = true }
        .sheet(isPresented: $showSheet) {
            ZStack {
                MilliColor.obsidian.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Milli AI")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Your financial AI assistant")
                        .foregroundStyle(Color(hex: "8E92A0"))
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
        Color(hex: "07090B").ignoresSafeArea()
        Text("Screen Content")
            .foregroundStyle(.white)
    }
    .withMilliAI()
}
