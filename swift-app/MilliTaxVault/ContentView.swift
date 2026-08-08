import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            PayoutsView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("Payouts")
                }
                .tag(1)
            
            MileageView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Mileage")
                }
                .tag(2)
            
            InvestingView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Invest")
                }
                .tag(3)
            
            MoreView()
                .tabItem {
                    Image(systemName: "ellipsis")
                    Text("More")
                }
                .tag(4)
        }
        .tint(.milliAccent)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color(hex: "0A0A0F"))
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.milliMuted)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.milliMuted)]
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.milliAccent)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.milliAccent)]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
}
