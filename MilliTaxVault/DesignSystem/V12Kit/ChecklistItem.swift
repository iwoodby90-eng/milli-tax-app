import SwiftUI

// MARK: - ChecklistItem
// Filing checklist (28) / onboarding steps (04) with verified states.
// Verified state requires authoritative confirmation — never rendered from
// completion of a local animation alone.

struct ChecklistItem: View {
    enum CheckState {
        case verified
        case pending
        case actionNeeded

        var icon: String {
            switch self {
            case .verified: return "checkmark.seal.fill"
            case .pending: return "circle.dashed"
            case .actionNeeded: return "exclamationmark.circle"
            }
        }

        var tint: Color {
            switch self {
            case .verified: return MilliColors.positive
            case .pending: return MilliColors.textTertiary
            case .actionNeeded: return MilliColors.warning
            }
        }

        var label: String {
            switch self {
            case .verified: return "VERIFIED"
            case .pending: return "PENDING"
            case .actionNeeded: return "ACTION NEEDED"
            }
        }
    }

    let title: String
    let detail: String
    let state: CheckState
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
        .accessibilityLabel("\(title), \(state.label)")
    }

    private var inner: some View {
        HStack(spacing: 12) {
            Image(systemName: state.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(state.tint)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer(minLength: 8)

            Text(state.label)
                .font(MilliFont.label)
                .tracking(0.5)
                .foregroundStyle(state.tint)
        }
        .padding(12)
        .obsidianGlassCard(cornerRadius: MilliSpacing.radiusMd)
    }
}