import SwiftUI

// MARK: - Legacy Milli AI Companion
// Kept as a compatibility surface for any older call sites. The production app shell uses
// MilliAIOrb in ContentView, which routes directly to MilliAIView. This wrapper now opens
// the same canonical assistant experience instead of presenting placeholder content.
//
// MILLI Deviation/Acceptance Spec v1 (Aug 28, 2026), section 4:
// the floating companion is a 56 pt full-body character with a soft cyan
// glow, floating above the bottom-right of the content (8 pt above the
// nav bar crest), NOT a small flat orb.

struct MilliAICompanion: View {
    @State private var floating = false
    @State private var showAssistant = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: { showAssistant = true }) {
            // 56 pt full-body character with soft cyan glow.
            MilliAICharacterView(size: 56, animated: true, state: .front)
                .shadow(color: MilliColors.cyanGlow.opacity(0.45), radius: 10)
        }
        .buttonStyle(.plain)
        .offset(y: floating ? -3 : 0)
        .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: floating)
        .padding(.bottom, 80)
        .padding(.trailing, 16)
        .accessibilityLabel("Open Milli AI")
        .onAppear {
            guard !reduceMotion else { return }
            floating = true
        }
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
