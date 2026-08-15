import SwiftUI

// MARK: - MilliAIOrb — Robot AI Companion (floating)
// Transparent floating companion with robot-like face.
// Placed ONCE at ContentView root level — never inside individual views.
struct MilliAIOrb: View {
    @State private var showAIChat = false
    
    var body: some View {
        Button(action: { showAIChat = true }) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .blur(radius: 8)
                
                // Dark circular body
                Circle()
                    .fill(Color(white: 0.1))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
                
                // Robot face
                VStack(spacing: 4) {
                    // Antenna
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 5, height: 5)
                        Rectangle()
                            .fill(Color.cyan.opacity(0.7))
                            .frame(width: 1.5, height: 8)
                    }
                    // Eyes
                    HStack(spacing: 8) {
                        Circle().fill(Color.cyan).frame(width: 6, height: 6)
                            .shadow(color: .cyan, radius: 3)
                        Circle().fill(Color.cyan).frame(width: 6, height: 6)
                            .shadow(color: .cyan, radius: 3)
                    }
                }
                .offset(y: -2)
            }
            .frame(width: 52, height: 52)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAIChat) {
            MilliAIChatView()
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                MilliAIOrb()
                    .padding(.trailing, 20)
                    .padding(.bottom, 104)
            }
        }
    }
}
