import SwiftUI

// MARK: - ContentView — Root container with tab routing and nav bar

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    @State private var showAIChat = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating AI Orb — bottom right, above nav
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    MilliAIOrb {
                        showAIChat = true
                    }
                    .padding(.trailing, MilliSpacing.screenHorizontal)
                    .padding(.bottom, 80) // Above nav bar
                }
            }

            // Bottom nav bar
            MilliNavBar(selectedTab: $selectedTab) {
                // M Dial tap — navigate home
                selectedTab = .home
            }
        }
        .background(MilliColors.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    // MARK: - Tab Content Router

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .payouts:
            PayoutsPlaceholderView()
        case .mDial:
            HomeView() // M always routes home
        case .mileage:
            MileagePlaceholderView()
        case .more:
            MorePlaceholderView()
        }
    }
}

// MARK: - Placeholder views for tabs not yet built

struct PayoutsPlaceholderView: View {
    var body: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(MilliColors.cyan)
                Text("Payouts")
                    .font(MilliFont.headline())
                    .foregroundColor(MilliColors.textPrimary)
                Text("Coming soon")
                    .font(MilliFont.bodySmall())
                    .foregroundColor(MilliColors.textSecondary)
            }
        }
    }
}

struct MileagePlaceholderView: View {
    var body: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(MilliColors.cyan)
                Text("Mileage")
                    .font(MilliFont.headline())
                    .foregroundColor(MilliColors.textPrimary)
                Text("Coming soon")
                    .font(MilliFont.bodySmall())
                    .foregroundColor(MilliColors.textSecondary)
            }
        }
    }
}

struct MorePlaceholderView: View {
    var body: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(MilliColors.cyan)
                Text("More")
                    .font(MilliFont.headline())
                    .foregroundColor(MilliColors.textPrimary)
                Text("Coming soon")
                    .font(MilliFont.bodySmall())
                    .foregroundColor(MilliColors.textSecondary)
            }
        }
    }
}
