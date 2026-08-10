import SwiftUI

struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSubscription = false

    var body: some View {
        ZStack {
            Color.milliBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                MilliPageHeader(title: "More")

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        // User info section
                        if let user = appState.currentUser {
                            MilliCard {
                                HStack(spacing: 14) {
                                    Circle()
                                        .fill(Color.milliCyan.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(user.name.prefix(1)))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.milliCyan)
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(user.email)
                                            .font(.system(size: 12))
                                            .foregroundColor(.milliTextSecondary)
                                    }
                                    Spacer()
                                }
                            }
                        }

                        // TOOLS SECTION
                        sectionHeader("TOOLS")

                        NavigationLink(destination: MilliCentsView()) {
                            moreRowContent(icon: "centsign.circle.fill", label: "Milli Cents", color: .milliCyan)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: ExpensesView()) {
                            moreRowContent(icon: "creditcard.fill", label: "Expenses & Deductions", color: .milliCyan)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: ReportsView()) {
                            moreRowContent(icon: "chart.bar.fill", label: "Reports", color: .milliCyan)
                        }
                        .buttonStyle(.plain)

                        // WEALTH SECTION
                        sectionHeader("WEALTH")

                        NavigationLink(destination: InvestingView()) {
                            moreRowContent(icon: "chart.line.uptrend.xyaxis", label: "Investing", color: .milliSuccess)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: RetirementView()) {
                            moreRowContent(icon: "hourglass.circle.fill", label: "Retirement", color: .milliSuccess)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: WealthOverviewView()) {
                            moreRowContent(icon: "banknote.fill", label: "Wealth Overview", color: .milliSuccess)
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: TreeOfLifeView().environmentObject(appState)) {
                            moreRowContent(icon: "leaf.fill", label: "Tree of Life", color: .milliSuccess, badge: "ELITE")
                        }
                        .buttonStyle(.plain)

                        NavigationLink(destination: LifeEventsView()) {
                            moreRowContent(icon: "calendar.badge.clock", label: "Life Events", color: .milliSuccess)
                        }
                        .buttonStyle(.plain)

                        // ACCOUNT SECTION
                        sectionHeader("ACCOUNT")

                        moreRow(icon: "person.circle.fill", label: "Profile & Settings", color: .white)
                        moreRow(icon: "sparkles", label: "Milli AI Assistant", color: .milliCyan)
                        moreRow(icon: "doc.text.fill", label: "Export Reports", color: .white)
                        moreRow(icon: "folder.fill", label: "Tax Documents", color: .white)
                        moreRow(icon: "building.columns.fill", label: "Connected Banks", color: .white)

                        // Subscription row
                        Button(action: { showSubscription = true }) {
                            MilliCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.milliWarning)
                                        .frame(width: 28)

                                    Text("Subscription")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    if let tier = appState.currentUser?.tier {
                                        Text(tierDisplayName(tier))
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.milliCyan)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.milliCyan.opacity(0.1))
                                            .cornerRadius(6)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.milliTextTertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        moreRow(icon: "questionmark.circle.fill", label: "Help & Support", color: .white)
                        moreRow(icon: "info.circle.fill", label: "About Milli", color: .white)

                        // Logout
                        if appState.isAuthenticated {
                            Button(action: { appState.logout() }) {
                                MilliCard {
                                    HStack(spacing: 14) {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(Color(hex: "FF3D57"))
                                            .frame(width: 28)
                                        Text("Log Out")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color(hex: "FF3D57"))
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 100)
                }
            }

            // Full-screen cover for Subscription
            if showSubscription {
                SubscriptionView()
                    .environmentObject(appState)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSubscription)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundColor(.milliTextTertiary)
            Spacer()
        }
        .padding(.top, 12)
        .padding(.bottom, 2)
        .padding(.leading, 4)
    }

    // MARK: - Row Content (for NavigationLink)

    private func moreRowContent(icon: String, label: String, color: Color, badge: String? = nil) -> some View {
        MilliCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(0.3)
                        .foregroundColor(.milliWarning)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.milliWarning.opacity(0.12))
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.milliTextTertiary)
            }
        }
    }

    // MARK: - Static Row

    private func moreRow(icon: String, label: String, color: Color) -> some View {
        MilliCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.milliTextTertiary)
            }
        }
    }

    private func tierDisplayName(_ tier: String) -> String {
        switch tier.lowercased() {
        case "basic": return "MILLI Basic"
        case "pro": return "MILLI Pro"
        case "elite": return "MILLI Elite"
        default: return "Trial"
        }
    }
}
