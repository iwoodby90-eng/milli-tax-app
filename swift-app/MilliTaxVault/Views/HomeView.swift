import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            MilliPalette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with greeting
                    headerSection
                    // Hero balance card
                    balanceCard
                    // Quick stats row
                    statsRow
                    // Tax ready score
                    taxReadyCard
                    // Recent activity
                    recentActivity

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .task { await vm.loadDashboard() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(greeting)")
                    .font(.system(size: 14))
                    .foregroundColor(MilliPalette.textSecondary)
                Text(appState.user?.name.components(separatedBy: " ").first ?? "Driver")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            // Chrome wordmark
            Text("MILLI")
                .font(.system(size: 14, weight: .bold))
                .tracking(2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [MilliPalette.chrome1, MilliPalette.chrome2],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.bottom, 4)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Morning,"
        case 12..<17: return "Afternoon,"
        default: return "Evening,"
        }
    }

    // MARK: - Balance Card (Hero)

    private var balanceCard: some View {
        DKCard {
            VStack(spacing: 12) {
                Text("AVAILABLE TO SPEND")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2)
                    .foregroundColor(MilliPalette.textSecondary)

                Text(vm.availableToSpend)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 16) {
                    miniStat(label: "Latest Payout", value: vm.latestPayoutAmount, sublabel: vm.latestPayoutDate)
                    Divider().frame(height: 32).background(MilliPalette.cardBorder)
                    miniStat(label: "Vault Balance", value: vm.vaultBalance, sublabel: "\(vm.vaultGoalPercent)% to goal")
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func miniStat(label: String, value: String, sublabel: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(MilliPalette.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(sublabel)
                .font(.system(size: 10))
                .foregroundColor(MilliPalette.accent)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            MilliStatTile(title: "Quarterly Est.", value: vm.quarterlyEstimate, accent: MilliPalette.accent)
            MilliStatTile(title: "Tax Rate", value: "25%", accent: MilliPalette.textPrimary)
        }
    }

    // MARK: - Tax Ready Score

    private var taxReadyCard: some View {
        DKCard {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tax Ready Score")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Keep saving to improve your score")
                        .font(.system(size: 11))
                        .foregroundColor(MilliPalette.textSecondary)
                }
                Spacer()
                CircularProgressView(progress: Double(vm.vaultGoalPercent) / 100.0, size: 56, lineWidth: 5)
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivity: some View {
        DKCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Activity")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("View All")
                        .font(.system(size: 12))
                        .foregroundColor(MilliPalette.accent)
                }

                ForEach(0..<3) { i in
                    activityRow(
                        icon: ["bolt.fill", "car.fill", "arrow.up.circle.fill"][i],
                        title: ["Spark Payout", "Mileage Logged", "Vault Transfer"][i],
                        amount: ["$312.64", "24.8 mi", "$78.16"][i],
                        date: ["Aug 10", "Aug 9", "Aug 8"][i],
                        color: [MilliPalette.positive, MilliPalette.accent, MilliPalette.accent][i]
                    )
                    if i < 2 {
                        Divider().background(MilliPalette.cardBorder)
                    }
                }
            }
        }
    }

    private func activityRow(icon: String, title: String, amount: String, date: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Text(date)
                    .font(.system(size: 11))
                    .foregroundColor(MilliPalette.textSecondary)
            }
            Spacer()
            Text(amount)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}
