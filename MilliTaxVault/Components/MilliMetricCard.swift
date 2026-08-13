import SwiftUI

// MARK: - MilliMetricCard — Reusable for 2x2 Grid
// Compact, dense, premium graphite surface.
// Shows: title label, primary value, subtitle detail.

struct MilliMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    var icon: String? = nil
    var iconColor: Color = MilliColors.cyan
    var valueColor: Color = .white
    var customContent: AnyView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: MilliLayout.metadataGap + 2) {
            // Title row
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title.uppercased())
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textSecondary)
                    .tracking(0.6)
            }
            
            if let custom = customContent {
                custom
            } else {
                // Primary value
                Text(value)
                    .font(MilliFont.cardValue)
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            // Subtitle
            Text(subtitle)
                .font(MilliFont.metadata)
                .foregroundStyle(MilliColors.textMuted)
                .lineLimit(1)
        }
        .padding(.horizontal, MilliLayout.cardPaddingH)
        .padding(.vertical, MilliLayout.cardPaddingV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .milliSurface()
    }
}
