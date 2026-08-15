import SwiftUI

// MARK: - MoreMenuView
// Secondary product hub. Primary navigation stays Home / Payouts / M / Mileage / More.

struct MoreMenuView: View {
    var navigate: ((ActiveScreen) -> Void)?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header

                sectionTitle("GIG & TAX TOOLS")
                menuTile(icon: "gauge.with.dots.needle.67percent", title: "Milli Cents™", subtitle: "Analyze a gig offer before you accept it", color: MilliColors.cyanGlow) { navigate?(.milliCents) }
                menuTile(icon: "lock.shield.fill", title: "Milli Tax Vault™", subtitle: "Protected tax reserve and ledger", color: MilliColors.deepCyan) { navigate?(.taxVault) }
                menuTile(icon: "checkmark.seal.fill", title: "Tax Ready Score™", subtitle: "See how prepared you are for tax season", color: MilliColors.positive) { navigate?(.taxReadyScore) }
                menuTile(icon: "calendar.badge.clock", title: "Quarterly Taxes", subtitle: "Estimate, prepare, and track payments", color: MilliColors.warning) { navigate?(.quarterlyTaxes) }

                sectionTitle("BUILD WEALTH")
                menuTile(icon: "chart.xyaxis.line", title: "Investing", subtitle: "Markets, holdings, and portfolio performance", color: MilliColors.cyanGlow) { navigate?(.investing) }
                menuTile(icon: "building.columns.fill", title: "Retirement", subtitle: "Contribution-based retirement projections", color: MilliColors.positive) { navigate?(.retirement) }
                menuTile(icon: "tree.fill", title: "Tree of Life", subtitle: "Plan life events against your financial future", color: MilliColors.cyanGlow) { navigate?(.treeOfLife) }

                sectionTitle("INSIGHTS")
                menuTile(icon: "doc.text.fill", title: "Reports", subtitle: "Deductions, trips, exports, and summaries", color: Color(hex: "7C8CFF")) { navigate?(.reports) }
                menuTile(icon: "sparkles", title: "Milli AI", subtitle: "Personalized intelligence across your money", color: MilliColors.cyanGlow) { navigate?(.milliAI) }

                sectionTitle("ACCOUNT")
                menuTile(icon: "gearshape.fill", title: "Settings", subtitle: "Profile, security, plan, and preferences", color: MilliColors.silver) {}
                menuTile(icon: "questionmark.circle.fill", title: "Help Center", subtitle: "Support and product guidance", color: MilliColors.textSecondary) {}
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Text("More")
                .font(MilliFont.screenTitle)
                .foregroundStyle(MilliColors.textPrimary)
            Spacer()
            Image("MilliMLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .opacity(0.78)
        }
        .padding(.bottom, 2)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    private func menuTile(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(color.opacity(0.09)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MilliFont.headlineSmall)
                        .foregroundStyle(MilliColors.textPrimary)
                    Text(subtitle)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            .milliCard(padding: 11)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoreMenuView()
        .preferredColorScheme(.dark)
}
