import SwiftUI

// MARK: - AIInsightCard
// MILLI AI supporting intelligence layer (08, 17, 22, 23, 24). Never obscures
// controls; uses the approved humanoid family states only. Success state is
// gated on authoritative confirmation.

struct AIInsightCard: View {
    enum AIState {
        case listening      // only while the user is speaking
        case thinking       // during processing
        case speaking       // while answering
        case success        // only after authoritative confirmed success
        case alert          // genuine warning/error states only

        var icon: String {
            switch self {
            case .listening: return "waveform"
            case .thinking: return "sparkles"
            case .speaking: return "bubble.left.fill"
            case .success: return "checkmark.seal.fill"
            case .alert: return "exclamationmark.triangle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .listening, .thinking, .speaking: return MilliColors.cyanGlow
            case .success: return MilliColors.positive
            case .alert: return MilliColors.warning
            }
        }

        var stateLabel: String {
            switch self {
            case .listening: return "LISTENING"
            case .thinking: return "THINKING"
            case .speaking: return "MILLI AI"
            case .success: return "CONFIRMED"
            case .alert: return "ATTENTION"
            }
        }
    }

    let state: AIState
    let text: String
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { inner }
                    .buttonStyle(.plain)
            } else {
                inner
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("MILLI AI insight: \(text)")
    }

    private var inner: some View {
        HStack(spacing: 12) {
            Image("MilliAIOrb")
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(state.tint.opacity(0.55), lineWidth: 0.8)
                )
                .shadow(color: state.tint.opacity(0.25), radius: 5)

            VStack(alignment: .leading, spacing: 3) {
                Text(state.stateLabel)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.7)
                    .foregroundStyle(state.tint)
                Text(text)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state.tint)
        }
        .padding(12)
        .obsidianGlassCard(cornerRadius: MilliSpacing.radiusLg)
    }
}