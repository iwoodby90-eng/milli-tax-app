import SwiftUI

// MARK: - ChartPanel (v1.2)
// One chart component family: growth chart (17), performance chart (18),
// forecast (19), spend trend (15), weekly bars (11), wealth-path comparison (22).
// Cyan primary series, silver/neutral secondary; green/red only for meaningful
// positive/negative states. Horizon and data status always labeled.

struct ChartPanel: View {
    enum ChartKind {
        case line
        case bars
    }

    let title: String
    let kind: ChartKind
    let data: [Double]
    var secondaryData: [Double]?
    var horizonLabel: String
    var provenance: ProvenanceState
    var height: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title.uppercased())
                    .font(MilliFont.sectionLabel)
                    .tracking(0.7)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer(minLength: 0)
                ProvenanceTag(state: provenance)
            }

            chartBody

            HStack {
                Text(horizonLabel)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
                Spacer(minLength: 0)
                legend
            }
        }
        .padding(14)
        .obsidianGlassCard(cornerRadius: MilliSpacing.radiusLg)
    }

    @ViewBuilder
    private var chartBody: some View {
        switch kind {
        case .line:
            MilliSparkline(
                data: data,
                color: MilliColors.cyanGlow,
                height: height,
                lineWidth: 1.8
            )
        case .bars:
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, value in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(
                            value >= 0
                                ? LinearGradient(
                                    colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    colors: [MilliColors.negative.opacity(0.8), MilliColors.negative.opacity(0.4)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(height: max(4, CGFloat(value) / max((data.max() ?? 1), 1) * height))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: height, alignment: .bottom)
        }
    }

    @ViewBuilder
    private var legend: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                Circle().fill(MilliColors.cyanGlow).frame(width: 5, height: 5)
                Text("Primary")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
            if secondaryData != nil {
                HStack(spacing: 4) {
                    Circle().fill(MilliColors.silver).frame(width: 5, height: 5)
                    Text("Secondary")
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                }
            }
        }
    }
}