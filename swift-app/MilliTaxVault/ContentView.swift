import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showMilliAI = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Page content — full screen
            Color(hex: "0A0A0F").ignoresSafeArea()
            
            currentView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
            
            // Floating Milli AI orb — bottom right, above nav
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
        case .wealth:   WealthOverviewView()
        case .home:     HomeView()
        case .activity: ReportsView()
        case .cockpit:  MoreView()
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
                            .fill(Color(hex: "00B4FF").opacity(0.25))
                            .frame(width: 64, height: 64)
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
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color(hex: "00B4FF").opacity(0.8), Color(hex: "00B4FF").opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        // Label
                        VStack(spacing: 1) {
                            Text("AI")
                                .font(.system(size: 13, weight: .black, design: .default))
                                .foregroundColor(.white)
                            Circle()
                                .fill(Color(hex: "00B4FF"))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.trailing, 18)
                .padding(.bottom, 98)
            }
        }
    }
}
