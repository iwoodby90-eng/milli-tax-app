import SwiftUI

// MARK: - MoreMenuView — Screen 12: More/Cockpit tab
// Grid of navigation tiles leading to sub-screens:
// Investing, Retirement, Tree of Life, Reports, Settings (Cockpit)

struct MoreMenuView: View {
    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                // MARK: - Header
                headerSection

                // MARK: - Wealth Section
                sectionTitle("WEALTH")
                VStack(spacing: MilliSpacing.md) {
                    menuTile(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Investing",
                        subtitle: "Portfolio & market insights",
                        color: MilliColors.cyan
                    ) { navigate?(.investing) }

                    menuTile(
                        icon: "building.columns.fill",
                        title: "Retirement",
                        subtitle: "IRA & 401(k) planning",
                        color: MilliColors.green
                    ) { navigate?(.retirement) }

                    menuTile(
                        icon: "tree.fill",
                        title: "Tree of Life",
                        subtitle: "Financial milestones",
                        color: MilliColors.amber
                    ) { navigate?(.treeOfLife) }
                }

                // MARK: - Insights Section
                sectionTitle("INSIGHTS")
                VStack(spacing: MilliSpacing.md) {
                    menuTile(
                        icon: "doc.text.fill",
                        title: "Reports",
                        subtitle: "Deductions & tax summaries",
                        color: Color(hex: "9C27B0")
                    ) { navigate?(.reports) }
                }

                // MARK: - Account Section
                sectionTitle("ACCOUNT")
                VStack(spacing: MilliSpacing.md) {
                    menuTile(
                        icon: "gearshape.fill",
                        title: "Settings",
                        subtitle: "Profile, plan & preferences",
                        color: MilliColors.silver
                    ) {
                        // Future: navigate to cockpit/settings
                    }

                    menuTile(
                        icon: "questionmark.circle.fill",
                        title: "Help Center",
                        subtitle: "Support & FAQs",
                        color: MilliColors.secondaryText
                    ) {
                        // Future: navigate to help
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("More")
                .font(MilliFont.screenTitle)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Section Title

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)
            .padding(.top, MilliSpacing.sm)
    }

    // MARK: - Menu Tile

    private func menuTile(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(MilliFont.headline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(MilliFont.caption)
                        .foregroundColor(MilliColors.secondaryText)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(white: 0.3))
            }
            .padding(MilliSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                    .fill(MilliColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MilliSpacing.radiusLg, style: .continuous)
                            .stroke(MilliColors.cardBorderGlow, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoreMenuView()
        .preferredColorScheme(.dark)
}
