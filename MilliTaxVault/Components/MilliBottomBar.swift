import SwiftUI

// MARK: - MilliBottomBar — Custom Native Bottom Navigation
// Dark bar, visually integrated, not stock TabView appearance.
// Tabs: Home, Payouts, [M center], Mileage, More
// Center M elevated above bar. Selected: cyan. Inactive: silver/gray.

struct MilliBottomBar: View {
    @Binding var selectedTab: MilliTab
    
    private let barHeight: CGFloat = MilliLayout.bottomNavHeight
    
    var body: some View {
        ZStack(alignment: .top) {
            // Bar background
            Rectangle()
                .fill(Color(hex: "080C12").opacity(0.97))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 0.5)
                }
                .frame(height: barHeight)
                .ignoresSafeArea(edges: .bottom)
            
            // Tab items
            HStack(spacing: 0) {
                tabButton(.dashboard, icon: "house.fill", label: "Home")
                tabButton(.activity, icon: "banknote.fill", label: "Payouts")
                
                // Center M button — elevated
                MilliCenterMButton {
                    selectedTab = .home
                }
                .offset(y: -18)
                .frame(maxWidth: .infinity)
                
                tabButton(.transfers, icon: "car.fill", label: "Mileage")
                tabButton(.more, icon: "ellipsis", label: "More")
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .frame(height: barHeight)
    }
    
    @ViewBuilder
    private func tabButton(_ tab: MilliTab, icon: String, label: String) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        selectedTab == tab ? MilliColors.cyan : MilliColors.inactiveTab
                    )
                Text(label)
                    .font(MilliFont.navLabel)
                    .foregroundStyle(
                        selectedTab == tab ? MilliColors.cyan : MilliColors.inactiveTab
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }
}
