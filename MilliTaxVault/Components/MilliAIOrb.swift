import SwiftUI

// MARK: - MilliAIOrb — Transparent Floating AI Companion
// NO background square, NO border. Pure glowing icon.
struct MilliAIOrb: View {
    @State private var showAIChat = false
    
    var body: some View {
        Image(systemName: "brain.head.profile")
            .font(.system(size: 28, weight: .medium))
            .frame(width: 52, height: 52)
            .foregroundColor(Color(hex: "00E5FF"))
            .shadow(color: Color(hex: "00E5FF").opacity(0.6), radius: 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.bottom, 108)
            .padding(.trailing, 20)
            .onTapGesture {
                showAIChat = true
            }
            .sheet(isPresented: $showAIChat) {
                MilliAIChatView()
            }
    }
}

// MARK: - MilliAIChatView — AI Chat Sheet
struct MilliAIChatView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.2))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
            
            // Header
            HStack {
                Text("Milli AI")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            
            // Placeholder content
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "00E5FF"))
                    .shadow(color: Color(hex: "00E5FF").opacity(0.5), radius: 12)
                
                Text("How can I help you today?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .frame(maxHeight: .infinity)
            
            Spacer()
        }
        .background(Color(hex: "0A0A0C").ignoresSafeArea())
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        MilliAIOrb()
    }
}
