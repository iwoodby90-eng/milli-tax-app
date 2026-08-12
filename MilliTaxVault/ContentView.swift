import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Screen content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .payouts:
                    PayoutsPlaceholderView()
                case .vault:
                    TaxVaultView()
                case .mileage:
                    MilagePlaceholderView()
                case .more:
                    MorePlaceholderView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Nav bar
            MilliNavBar(selectedTab: $selectedTab)
        }
        .background(MilliColor.obsidian)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
    }
}

// Placeholder screens for Phase 1
struct PayoutsPlaceholderView: View {
    var body: some View {
        ZStack {
            MilliColor.obsidian.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Payouts")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("Coming in Phase 2")
                    .foregroundStyle(MilliColor.textMuted)
            }
        }
    }
}

struct MilagePlaceholderView: View {
    var body: some View {
        ZStack {
            MilliColor.obsidian.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Mileage")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("Coming in Phase 3")
                    .foregroundStyle(MilliColor.textMuted)
            }
        }
    }
}

struct MorePlaceholderView: View {
    var body: some View {
        ZStack {
            MilliColor.obsidian.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("More")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                Text("Coming soon")
                    .foregroundStyle(MilliColor.textMuted)
            }
        }
    }
}
