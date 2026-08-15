import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @State private var selectedTab: MilliTab = .home
    
    var body: some View {
        ZStack {
            // Tab content + nav bar
            ZStack(alignment: .bottom) {
                // Screen content — each screen fills the available space
                Group {
                    switch selectedTab {
                    case .dashboard:
                        HomeView()
                    case .activity:
                        ActivityView()
                    case .home:
                        HomeView()
                    case .wealth:
                        WealthView()
                    case .transfers:
                        MileageView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 120)
                }
                
                // Brushed nickel automotive dashboard navigation bar
                MilliNavBar(selectedTab: $selectedTab)
            }
            
            // GLOBAL AI ORB — only visible after onboarding complete
            if hasCompletedOnboarding && hasCompletedSetup {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MilliAIOrb()
                            .padding(.trailing, 20)
                            .padding(.bottom, 104)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(true)
                .zIndex(999)
            }
        }
        .background(MilliColors.obsidian)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
