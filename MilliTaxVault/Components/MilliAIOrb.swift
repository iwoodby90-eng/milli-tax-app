import SwiftUI

// MARK: - MilliAIOrb — Transparent Floating AI Companion
// NO background fill, NO border. Pure glowing icon.
// Placed ONCE at ContentView root level — never inside individual views.
struct MilliAIOrb: View {
    @State private var showAIChat = false
    
    var body: some View {
        Image(systemName: "brain.head.profile")
            .font(.system(size: 28, weight: .medium))
            .frame(width: 52, height: 52)
            .foregroundColor(Color(hex: "00E5FF"))
            .shadow(color: Color(hex: "00E5FF").opacity(0.6), radius: 16)
            .contentShape(Circle())
            .onTapGesture {
                showAIChat = true
            }
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
