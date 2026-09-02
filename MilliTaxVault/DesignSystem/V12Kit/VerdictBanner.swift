import SwiftUI

// MARK: - VerdictBanner
// GO/MAYBE/NO analyzer verdict (screen 14). Verdict is computed, never
// decorative; strict color mapping: Positive #22DB83 / Warning #F4B73B /
// Negative #FF5661 — no other colorways.

struct VerdictBanner: View {
    enum Verdict {
        case go
        case maybe
        case no

        var label: String {
            switch self {
            case .go: return "GO"
            case .maybe: return "MAYBE"
            case .no: return "NO"
            }
        }

        var tint: Color {
            switch self {
            case .go: return MilliColors.positive
            case .maybe: return MilliColors.warning
            case .no: return MilliColors.negative
            }
        }

        var caption: String {
            switch self {
            case .go: return "Profitable offer — accept"
            case .maybe: return "Marginal — review the numbers"
            case .no: return "Not profitable — decline"
            }
        }
    }

    let verdict: Verdict
    var score: Int?
    var scoreLabel: String = "PROFITABILITY SCORE™"

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(verdict.label)
                    .font(MilliFont.displaySmall)
                    .foregroundStyle(verdict.tint)
                    .tracking(1.2)
                Text(verdict.caption)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            Spacer(minLength: 8)
            if let score {
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(MilliFont.numericLarge)
                        .monospacedDigit()
                        .foregroundStyle(verdict.tint)
                    Text(scoreLabel)
                        .font(MilliFont.label)
                        .tracking(0.5)
                        .foregroundStyle(MilliColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: verdict.tint.opacity(0.10), location: 0),
                            .init(color: MilliColors.carbon.opacity(0.6), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                        .stroke(verdict.tint.opacity(0.45), lineWidth: 0.9)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verdict \(verdict.label). \(verdict.caption)")
    }
}