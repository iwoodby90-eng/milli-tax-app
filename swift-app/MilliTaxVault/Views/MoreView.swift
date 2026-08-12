import SwiftUI

// MARK: - Cockpit View (Settings & Account)

struct MoreView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSubscription = false

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    MilliPageHeader(title: "Cockpit")

                    // Profile card
                    profileCard

                    // Subscription
                    subscriptionCard

                    // Settings sections
                    settingsSection

                    // Sign out
                    signOutButton

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        DKCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MilliPalette.accent.opacity(0.2), MilliPalette.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                    Text(initials)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(MilliPalette.accent)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.user?.name ?? "Milli User")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    Text(appState.user?.email ?? "")
                        .font(.system(size: 12))
                        .foregroundColor(MilliPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(MilliPalette.textSecondary)
            }
        }
    }

    private var initials: String {
        let name = appState.user?.name ?? ""
        let parts = name.components(separatedBy: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? String(parts.last!.first!) : ""
        return first + last
    }

    // MARK: - Subscription Card

    private var subscriptionCard: some View {
        DKCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Milli Pro")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MilliPalette.accent)
                    Text("Active subscription")
                        .font(.system(size: 12))
                        .foregroundColor(MilliPalette.textSecondary)
                }
                Spacer()
                Button {
                    showSubscription = true
                } label: {
                    Text("Manage")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MilliPalette.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(MilliPalette.accent.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 2) {
            settingsGroup(title: "App", items: [
                ("bell", "Notifications"),
                ("lock.shield", "Security"),
                ("paintpalette", "Appearance"),
            ])

            settingsGroup(title: "Tax", items: [
                ("building.columns", "Tax Profile"),
                ("doc.text", "Reports"),
                ("calendar", "Quarterly Reminders"),
            ])

            settingsGroup(title: "Support", items: [
                ("questionmark.circle", "Help Center"),
                ("envelope", "Contact Us"),
                ("star", "Rate Milli"),
            ])
        }
    }

    private func settingsGroup(title: String, items: [(String, String)]) -> some View {
        DKCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(MilliPalette.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 8)

                ForEach(items, id: \.1) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.0)
                            .font(.system(size: 14))
                            .foregroundColor(MilliPalette.accent)
                            .frame(width: 24)
                        Text(item.1)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(MilliPalette.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if item.1 != items.last?.1 {
                        Divider()
                            .background(MilliPalette.cardBorder)
                            .padding(.leading, 52)
                    }
                }
            }
            .padding(.bottom, 6)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            appState.logout()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.forward")
                    .font(.system(size: 14))
                Text("Sign Out")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(MilliPalette.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MilliPalette.negative.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MilliPalette.negative.opacity(0.2), lineWidth: 1)
            )
        }
    }
}
