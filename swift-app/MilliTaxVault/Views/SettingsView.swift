import SwiftUI

struct SettingsView: View {
    // Wire these to AppState / services in the app.
    var userName: String = "Ian Woodby"
    var userEmail: String = "you@example.com"
    var tier: String = "Milli Pro"
    var onConnectBanks: () -> Void = {}
    var onManageSubscription: () -> Void = {}
    var onSignOut: () -> Void = {}
    @State private var notificationsOn = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                profileCard
                DKCard {
                    VStack(spacing: 0) {
                        row(icon: "building.columns.fill", title: "Connected Banks", action: onConnectBanks)
                        divider
                        row(icon: "creditcard.fill", title: "Subscription " + tier, action: onManageSubscription)
                        divider
                        HStack {
                            Label("Notifications", systemImage: "bell.fill").foregroundStyle(MilliPalette.textPrimary)
                            Spacer()
                            Toggle("", isOn: $notificationsOn).labelsHidden().tint(MilliPalette.accent)
                        }.padding(.vertical, 10)
                    }
                }
                Button(action: onSignOut) {
                    Text("Sign Out").font(.headline).frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: MilliPalette.radius).fill(MilliPalette.negative.opacity(0.15)))
                        .foregroundStyle(MilliPalette.negative)
                }
            }.padding()
        }
        .background(MilliPalette.background.ignoresSafeArea())
        .navigationTitle("Settings")
    }
    private var profileCard: some View {
        DKCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(MilliPalette.accent.opacity(0.2)).frame(width: 56, height: 56)
                    Text(initials).font(.title3.weight(.bold)).foregroundStyle(MilliPalette.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(userName).font(.headline).foregroundStyle(MilliPalette.textPrimary)
                    Text(userEmail).font(.caption).foregroundStyle(MilliPalette.textSecondary)
                }
                Spacer()
            }
        }
    }
    private var initials: String {
        userName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
    private func row(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon).foregroundStyle(MilliPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(MilliPalette.textSecondary)
            }.padding(.vertical, 10)
        }.buttonStyle(.plain)
    }
    private var divider: some View { Divider().overlay(MilliPalette.cardBorder) }
}
