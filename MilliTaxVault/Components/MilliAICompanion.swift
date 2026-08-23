import SwiftUI

// MARK: - Legacy Milli AI Companion
// Kept as a compatibility surface for any older call sites. The production app shell uses
// MilliAIOrb in ContentView, which routes directly to MilliAIView. This wrapper now opens
// the same canonical assistant experience instead of presenting placeholder content.

struct MilliAICompanion: View {
    @State private var floating = false
    @State private var showAssistant = false

    var body: some View {
        Button(action: { showAssistant = true }) {
            MilliAICharacterView(size: 58, animated: true)
        }
        .buttonStyle(.plain)
        .offset(y: floating ? -3 : 0)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
        .padding(.bottom, 80)
        .padding(.trailing, 16)
        .accessibilityLabel("Open Milli AI")
        .onAppear { floating = true }
        .fullScreenCover(isPresented: $showAssistant) {
            MilliAIView(
                onBack: { showAssistant = false },
                navigate: nil
            )
            .preferredColorScheme(.dark)
        }
    }
}

// Compatibility modifier retained for any legacy screens that still apply it.
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
