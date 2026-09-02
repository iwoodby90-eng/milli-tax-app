import SwiftUI

// MARK: - StatusRow
// One row component for payout rows (09), expense rows (15), holdings (18),
// document rows (27), platform tiles (06), bank rows (16), life-event rows (21),
// report cards (26), timeline events (23). Material and density variants.

struct StatusRow: View {
    enum Material { case obsidian, carbon }
    enum Density { case comfortable, compact }

    enum StateChip: Hashable {
        case confirmed        // authoritative positive
        case pending
        case connected
        case failed
        case neutral(String)

        var label: String {
            switch self {
            case .confirmed: return "CONFIRMED"
            case .pending: return "PENDING"
            case .connected: return "CONNECTED"
            case .failed: return "FAILED"
            case .neutral(let text): return text
            }
        }

        var tint: Color {
            switch self {
            case .confirmed, .connected: return MilliColors.positive
            case .pending: return MilliColors.warning
            case .failed: return MilliColors.negative
            case .neutral: return MilliColors.textSecondary
            }
        }
    }

    let icon: String
    let title: String
    var subtitle: String?
    var value: String?
    var valueTint: Color = MilliColors.textPrimary
    var chip: StateChip?
    var provenance: ProvenanceState?
    var material: Material = .obsidian
    var density: Density = .comfortable
    var action: (() -> Void)?

    private var verticalSpacing: CGFloat { density == .comfortable ? 10 : 7 }
    private var rowPadding: CGFloat { density == .comfortable ? 14 : 11 }

    var body: some View {
        Group {
            if let action {
                Button(action: action) { inner }
                    .buttonStyle(.plain)
            } else {
                inner
            }
        }
    }

    private var inner: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.white.opacity(0.04)))
                .overlay(Circle().stroke(MilliColors.borderSubtle, lineWidth: 0.6))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                        .lineLimit(1)
                    if let provenance {
                        ProvenanceTag(state: provenance)
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let value {
                Text(value)
                    .font(MilliFont.numericSmall)
                    .monospacedDigit()
                    .foregroundStyle(valueTint)
            }
            if let chip {
                Text(chip.label)
                    .font(MilliFont.label)
                    .tracking(0.5)
                    .foregroundStyle(chip.tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(chip.tint.opacity(0.10)))
            }
        }
        .padding(.horizontal, rowPadding)
        .padding(.vertical, verticalSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(materialBackground)
    }

    @ViewBuilder
    private var materialBackground: some View {
        switch material {
        case .obsidian: Rectangle().fill(Color.clear).obsidianGlassCard(cornerRadius: MilliSpacing.radiusMd)
        case .carbon: Rectangle().fill(Color.clear).carbonCard(cornerRadius: MilliSpacing.radiusMd)
        }
    }
}