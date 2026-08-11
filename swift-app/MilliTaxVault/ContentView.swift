import SwiftUI

enum MilliTab: Int, CaseIterable {
    case home, payouts, vault, mileage, more
    var title: String {
        switch self {
        case .home: return "Home"
        case .payouts: return "Payouts"
        case .vault: return "Vault"
        case .mileage: return "Mileage"
        case .more: return "More"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .payouts: return "dollarsign.circle.fill"
        case .vault: return "lock.shield.fill"
        case .mileage: return "car.fill"
        case .more: return "ellipsis"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var tab: MilliTab = .home
    @State private var showAI = false

    var body: some View {
        ZStack(alignment: .bottom) {
            MilliPalette.background.ignoresSafeArea()

            NavigationStack {
                Group {
                    switch tab {
                    case .home: HomeView()
                    case .payouts: PayoutsView()
                    case .vault: TaxVaultView()
                    case .mileage: MileageView()
                    case .more: MoreView()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 76) }

            floatingOrb
            BottomNavBar(selection: $tab) { showAI = true }
        }
        .sheet(isPresented: $showAI) { MilliAIView() }
    }

    private var floatingOrb: some View {
        HStack {
            Spacer()
            Button { showAI = true } label: {
                ZStack {
                    Circle().fill(RadialGradient(colors: [MilliPalette.accent, MilliPalette.accent.opacity(0.4)],
                                                 center: .center, startRadius: 1, endRadius: 26))
                        .frame(width: 52, height: 52)
                        .shadow(color: MilliPalette.accent.opacity(0.7), radius: 14)
                    Image(systemName: "sparkles").foregroundStyle(.black).font(.system(size: 20, weight: .bold))
                }
            }.padding(.trailing, 22).padding(.bottom, 92)
        }
    }
}
