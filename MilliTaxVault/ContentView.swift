import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MilliTab = .home
    @State private var showTreeOfLife: Bool = false
    
    var body: some View {
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
                case .more:
                    MoreView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                // Reserve space for the sculpted nav bar so content doesn't hide behind it
                Color.clear.frame(height: 120)
            }
            
            // Brushed nickel automotive dashboard navigation bar
            MilliNavBar(selectedTab: $selectedTab)
        }
        .background(MilliColors.obsidian)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
