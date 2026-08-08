import SwiftUI

enum AppTab {
    case vault, wealth, home, activity, cockpit
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showMilliAI = false
    @State private var appReady = false
    
    var body: some View {
        if !appReady {
            SplashView(onComplete: { appReady = true })
        } else {
            ZStack(alignment: .bottom) {
                // Main content
                Group {
                    switch selectedTab {
                    case .vault:    TaxVaultView()
                    case .wealth:   WealthOverviewView()
                    case .home:     HomeView()
                    case .activity: ReportsView()
                    case .cockpit:  MoreView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
                
                // Floating Milli AI button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showMilliAI = true }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "00B4FF").opacity(0.9), Color(hex: "0077CC")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 52, height: 52)
                                    .shadow(color: Color(hex: "00B4FF").opacity(0.5), radius: 12, x: 0, y: 4)
                                Text("AI")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                // Bel Air cockpit nav bar
                BelAirNavBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $showMilliAI) {
                MilliAIView()
            }
        }
    }
}

#Preview {
    ContentView()
}
