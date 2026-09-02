import SwiftUI

// MARK: - ProvenanceState
// Canonical truth labels (Brand Guidelines Section 07). Every financial figure
// carries one. No component may render a success/confirmed state without
// authoritative backend state.

enum ProvenanceState: String, CaseIterable, Hashable {
    case live = "LIVE"
    case cachedLive = "CACHED LIVE"
    case estimated = "ESTIMATED"
    case userEntered = "USER ENTERED"
    case demo = "DEMO"
    case preview = "PREVIEW"
    case unavailable = "UNAVAILABLE"

    var accessibilityLabel: String { rawValue }

    var tint: Color {
        switch self {
        case .live: return MilliColors.positive
        case .cachedLive: return MilliColors.cyanGlow
        case .estimated, .preview: return MilliColors.warning
        case .userEntered: return MilliColors.silver
        case .demo: return MilliColors.textTertiary
        case .unavailable: return MilliColors.negative
        }
    }
}

// MARK: - ProvenanceTag
// Truth-label chip. Appears on every financial figure across all 30 screens.
// Color reinforces state but is never the only carrier of meaning — the text
// label is always present.

struct ProvenanceTag: View {
    let state: ProvenanceState

    var body: some View {
        Text(state.rawValue)
            .font(MilliFont.label)
            .tracking(0.6)
            .foregroundStyle(state.tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(state.tint.opacity(0.10))
                    .overlay(
                        Capsule().stroke(state.tint.opacity(0.35), lineWidth: 0.6)
                    )
            )
            .accessibilityLabel("Data status: \(state.rawValue)")
    }
}