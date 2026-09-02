import SwiftUI

// MARK: - TimelineRail
// Vertical event rail with confirmed/pending states — Financial Timeline (23),
// reusable for Life Events (21). Cyan rail; status icons per node.

struct TimelineRail: View {
    struct Event: Identifiable {
        let id: String
        let icon: String
        let title: String
        let detail: String
        let amount: String?
        var confirmed: Bool
        var date: String?
    }

    let events: [Event]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                TimelineRailRow(event: event, isFirst: index == 0, isLast: index == events.count - 1)
            }
        }
    }

    private struct TimelineRailRow: View {
        let event: Event
        let isFirst: Bool
        let isLast: Bool

        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                // Rail + node
                VStack(spacing: 0) {
                    if !isFirst {
                        Rectangle()
                            .fill(MilliColors.cyanGlow.opacity(0.35))
                            .frame(width: 1.4)
                    }
                    ZStack {
                        Circle()
                            .fill(MilliColors.carbon)
                            .frame(width: 26, height: 26)
                            .overlay(
                                Circle().stroke(
                                    event.confirmed ? MilliColors.positive : MilliColors.cyanGlow.opacity(0.6),
                                    lineWidth: 1
                                )
                            )
                        Image(systemName: event.confirmed ? "checkmark" : event.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(event.confirmed ? MilliColors.positive : MilliColors.cyanGlow)
                    }
                    .frame(height: 26)
                    if !isLast {
                        Rectangle()
                            .fill(MilliColors.cyanGlow.opacity(0.35))
                            .frame(width: 1.4)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 26)

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(MilliFont.headlineSmall)
                            .foregroundStyle(MilliColors.textPrimary)
                        Text(event.detail)
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                    Spacer(minLength: 8)
                    if let amount {
                        Text(amount)
                            .font(MilliFont.numericSmall)
                            .monospacedDigit()
                            .foregroundStyle(event.confirmed ? MilliColors.positive : MilliColors.textSecondary)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity, alignment: .center)
                .obsidianGlassCard(cornerRadius: MilliSpacing.radiusMd)
                .padding(.bottom, isLast ? 0 : 10)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}