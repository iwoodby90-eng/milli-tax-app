import SwiftUI

// MARK: - SecurityPanel
// Privacy/audit trust-cue component — Gig Platforms (06), Tax Vault (10),
// Milli AI (24), Reports (26), Documents (27), Settings (30).

struct SecurityPanel: View {
    let title: String
    let lines: [String]

    init(title: String = "Security", _ lines: [String]) {
        self.title = title
        self.lines = lines
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
                Text(title.uppercased())
                    .font(MilliFont.sectionLabel)
                    .tracking(0.7)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .top, spacing: 7) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .padding(.top, 3)
                    Text(line)
                        .font(MilliFont.caption)
                        .foregroundStyle(MilliColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .carbonCard(cornerRadius: MilliSpacing.radiusLg)
        .accessibilityElement(children: .combine)
    }
}