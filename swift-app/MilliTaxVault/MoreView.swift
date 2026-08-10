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

                        moreRow(icon: "person.circle.fill", label: "Profile & Settings", color: .white)
                        moreRow(icon: "sparkles", label: "Milli AI Assistant", color: .milliCyan)
                        moreRow(icon: "doc.text.fill", label: "Export Reports", color: .white)
                        moreRow(icon: "folder.fill", label: "Tax Documents", color: .white)
                        moreRow(icon: "building.columns.fill", label: "Connected Banks", color: .white)

                        // Subscription row — navigates to SubscriptionView
                        Button(action: { showSubscription = true }) {
                            MilliCard {
                                HStack(spacing: 14) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 28)

                                    Text("Subscription")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    // Show current tier badge
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
