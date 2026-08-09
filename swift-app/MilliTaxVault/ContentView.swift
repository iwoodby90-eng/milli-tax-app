import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: AppTab = .home
    @State private var showMilliAI = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full screen background
            Color.milliBackground.ignoresSafeArea()

            // Page content
            currentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)

            // Floating Milli AI orb
            floatingAIButton

            // Bel Air cockpit nav bar
            BelAirNavBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showMilliAI) {
            MilliAIView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var currentView: some View {
        switch selectedTab {
        case .vault:    TaxVaultView()
        case .payouts:  PayoutsView()
        case .home:     HomeView()
        case .mileage:  MileageView()
        case .more:     MoreView()
        }
    }

    private var floatingAIButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showMilliAI = true }) {
                    ZStack {
                        // Glow
                        Circle()
                            .fill(Color.milliCyan.opacity(0.25))
                            .frame(width: 60, height: 60)
                            .blur(radius: 10)
                        // Body
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "0D3A5C"), Color(hex: "041825")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.milliCyan.opacity(0.8), Color.milliCyan.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        // Icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.milliCyan)
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 18)
                .padding(.bottom, 96)
            }
        }
    }
}
