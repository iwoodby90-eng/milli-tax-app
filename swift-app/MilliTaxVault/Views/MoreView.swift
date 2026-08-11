import SwiftUI

struct MoreView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                // User info
                if let user = appState.currentUser {
                    DKCard {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(MilliPalette.accent.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                Text(String(user.name.prefix(1)))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(MilliPalette.accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(user.name)
                                    .font(.headline)
                                    .foregroundStyle(MilliPalette.textPrimary)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundStyle(MilliPalette.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }

                // TOOLS
                sectionHeader("TOOLS")
                navRow(icon: "centsign.circle.fill", label: "Milli Cents", destination: AnyView(MilliCentsView()))
                navRow(icon: "creditcard.fill", label: "Expenses", destination: AnyView(ExpensesView()))
                navRow(icon: "chart.bar.fill", label: "Reports", destination: AnyView(ReportsView()))

                // WEALTH
                sectionHeader("WEALTH")
                navRow(icon: "chart.line.uptrend.xyaxis", label: "Investments", destination: AnyView(InvestmentsView()))
                navRow(icon: "hourglass.circle.fill", label: "Retirement", destination: AnyView(RetirementView()))
                navRow(icon: "banknote.fill", label: "Wealth Overview", destination: AnyView(WealthOverviewView()))
                navRow(icon: "leaf.fill", label: "Tree of Life", destination: AnyView(TreeOfLifeView()))
                navRow(icon: "chart.line.flattrend.xyaxis", label: "Retirement Projection", destination: AnyView(RetirementProjectionView()))
                navRow(icon: "calendar.badge.clock", label: "Life Events", destination: AnyView(LifeEventsView()))

                // ACCOUNT
                sectionHeader("ACCOUNT")
                navRow(icon: "gearshape.fill", label: "Settings", destination: AnyView(SettingsView()))
                navRow(icon: "crown.fill", label: "Subscription", destination: AnyView(SubscriptionView().environmentObject(appState)))

                // Sign Out
                if appState.isAuthenticated {
                    Button(action: { appState.logout() }) {
                        DKCard {
                            HStack(spacing: 14) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundStyle(MilliPalette.negative)
                                    .frame(width: 28)
                                Text("Sign Out")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(MilliPalette.negative)
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 88)
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("More")
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(MilliPalette.textSecondary)
            Spacer()
        }
        .padding(.top, 14)
        .padding(.bottom, 2)
        .padding(.leading, 4)
    }

    // MARK: - Navigation Row

    private func navRow(icon: String, label: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            DKCard {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(MilliPalette.accent)
                        .frame(width: 28)
                    Text(label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(MilliPalette.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(MilliPalette.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
