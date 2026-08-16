import SwiftUI

// MARK: - MoreMenuView
// Secondary product hub. Primary navigation stays Home / Payouts / M / Mileage / More.

struct MoreMenuView: View {
    var navigate: ((ActiveScreen) -> Void)?

    @State private var showSettings = false
    @State private var showHelp = false

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
                menuTile(icon: "gearshape.fill", title: "Settings", subtitle: "Security, notifications, and local preferences", color: MilliColors.silver) { showSettings = true }
                menuTile(icon: "questionmark.circle.fill", title: "Help Center", subtitle: "Product guidance and common questions", color: MilliColors.textSecondary) { showHelp = true }
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showSettings) {
            MilliSettingsSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHelp) {
            MilliHelpSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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

// MARK: - Settings

private struct MilliSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("milliBiometricUnlock") private var biometricUnlock = false
    @AppStorage("milliNotifications") private var notifications = true
    @AppStorage("milliAutopilotReceipts") private var autopilotReceipts = true
    @AppStorage("milliReduceDecorativeMotion") private var reduceDecorativeMotion = false

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        settingsSection(
                            title: "SECURITY",
                            rows: [
                                MilliSettingRow(
                                    icon: "faceid",
                                    title: "Biometric Unlock",
                                    subtitle: "Require device authentication before opening Milli",
                                    binding: $biometricUnlock
                                )
                            ]
                        )

                        settingsSection(
                            title: "AUTOPILOT",
                            rows: [
                                MilliSettingRow(
                                    icon: "checkmark.seal.fill",
                                    title: "Financial Receipts",
                                    subtitle: "Show an allocation receipt after Autopilot processing",
                                    binding: $autopilotReceipts
                                ),
                                MilliSettingRow(
                                    icon: "bell.badge.fill",
                                    title: "Notifications",
                                    subtitle: "Allow payout, reserve, mileage, and deadline reminders",
                                    binding: $notifications
                                )
                            ]
                        )

                        settingsSection(
                            title: "ACCESSIBILITY",
                            rows: [
                                MilliSettingRow(
                                    icon: "figure.walk.motion",
                                    title: "Reduce Decorative Motion",
                                    subtitle: "Keep financial state changes while reducing ambient motion",
                                    binding: $reduceDecorativeMotion
                                )
                            ]
                        )

                        VStack(alignment: .leading, spacing: 7) {
                            Text("PRODUCT")
                                .sectionHeaderStyle()
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Milli for iOS")
                                        .font(MilliFont.headlineSmall)
                                        .foregroundStyle(MilliColors.textPrimary)
                                    Text("Native SwiftUI")
                                        .font(MilliFont.caption)
                                        .foregroundStyle(MilliColors.textSecondary)
                                }
                                Spacer()
                                Image("MilliMLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 34, height: 34)
                            }
                            .milliCard(padding: 12)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func settingsSection(title: String, rows: [MilliSettingRow]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .sectionHeaderStyle()

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    Toggle(isOn: row.binding) {
                        HStack(spacing: 10) {
                            Image(systemName: row.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(MilliColors.cyanGlow)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .font(MilliFont.bodyMedium)
                                    .foregroundStyle(MilliColors.textPrimary)
                                Text(row.subtitle)
                                    .font(MilliFont.caption)
                                    .foregroundStyle(MilliColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .tint(MilliColors.cyanGlow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)

                    if index < rows.count - 1 {
                        Divider().overlay(Color.white.opacity(0.05)).padding(.leading, 52)
                    }
                }
            }
            .background(MilliCardBackground(showGlow: true))
        }
    }
}

private struct MilliSettingRow {
    let icon: String
    let title: String
    let subtitle: String
    let binding: Binding<Bool>
}

// MARK: - Help

private struct MilliHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let topics: [(String, String, String)] = [
        ("How does Milli Cents™ work?", "Milli Cents evaluates offer amount, total miles, dead distance, return distance, fuel cost, tax impact, net profit, and profit per mile before producing GO, MAYBE, or NO.", "gauge.with.dots.needle.67percent"),
        ("What is Milli Tax Vault™?", "The Tax Vault is the reserve and ledger experience used to separate estimated tax money from spendable income. Production transfers require a verified funding rail.", "lock.shield.fill"),
        ("How is Tax Ready Score™ calculated?", "The score summarizes readiness factors such as income tracking, expenses, mileage, tax payments, and document capture.", "checkmark.seal.fill"),
        ("What does Tree of Life plan?", "Tree of Life connects long-term financial targets with major life events such as a home, vehicle, marriage, children, education, business goals, and retirement.", "tree.fill"),
        ("Can Milli file or pay taxes yet?", "The interface clearly separates planning features from payment or filing functions that still require verified production partners and account connections.", "building.columns.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MilliColors.background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(topics.enumerated()), id: \.offset) { _, topic in
                            DisclosureGroup {
                                Text(topic.1)
                                    .font(MilliFont.bodySmall)
                                    .foregroundStyle(MilliColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 8)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: topic.2)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(MilliColors.cyanGlow)
                                        .frame(width: 30, height: 30)
                                        .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))
                                    Text(topic.0)
                                        .font(MilliFont.bodyMedium)
                                        .foregroundStyle(MilliColors.textPrimary)
                                }
                            }
                            .tint(MilliColors.cyanGlow)
                            .milliCard(padding: 12)
                        }
                    }
                    .padding(.horizontal, MilliSpacing.screenHorizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MilliColors.cyanGlow)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MoreMenuView()
        .preferredColorScheme(.dark)
}
