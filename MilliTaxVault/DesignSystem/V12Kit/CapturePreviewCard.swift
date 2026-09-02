import SwiftUI

// MARK: - CapturePreviewCard
// Live-state chip + timer + metrics for Active Trip Tracking (12);
// parameterized for any live-tracking surface.

struct CapturePreviewCard: View {
    struct Metric {
        let label: String
        let value: String
    }

    let liveLabel: String
    let metrics: [Metric]
    var primaryActionTitle: String
    var secondaryActionTitle: String?
    var primaryAction: () -> Void
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(MilliColors.cyanGlow)
                    .frame(width: 7, height: 7)
                Text(liveLabel)
                    .font(MilliFont.labelLarge)
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.cyanGlow)
                Spacer(minLength: 0)
                Text("RECORDING")
                    .font(MilliFont.label)
                    .tracking(0.6)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            HStack(spacing: 10) {
                ForEach(metrics, id: \.label) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.label)
                            .font(MilliFont.sectionLabel)
                            .tracking(0.5)
                            .foregroundStyle(MilliColors.textTertiary)
                        Text(metric.value)
                            .font(MilliFont.numericMedium)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 10) {
                if let secondaryActionTitle, let secondaryAction {
                    SecondaryGlassButton(title: secondaryActionTitle, action: secondaryAction)
                }
                PrimaryCTA(title: primaryActionTitle, action: primaryAction)
            }
        }
        .padding(16)
        .obsidianGlassCard(cornerRadius: MilliSpacing.radiusXl)
    }
}