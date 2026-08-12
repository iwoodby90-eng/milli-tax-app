import SwiftUI

enum MilliTab: Int, CaseIterable {
    case home, payouts, vault, mileage, more
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .payouts: return "creditcard.fill"
        case .vault: return "lock.shield.fill"
        case .mileage: return "location.fill"
        case .more: return "ellipsis"
        }
    }
    
    var label: String {
        switch self {
        case .home: return "Home"
        case .payouts: return "Payouts"
        case .vault: return "Tax Vault"
        case .mileage: return "Mileage"
        case .more: return "More"
        }
    }
}

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Bar background
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.01))
                .background(Color(hex: "080C12").opacity(0.97))
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(MilliColor.border)
                        .frame(height: 0.5)
                }
                .frame(height: 88)
                .ignoresSafeArea(edges: .bottom)
            
            HStack(spacing: 0) {
                // Home
                navItem(.home)
                // Payouts
                navItem(.payouts)
                
                // Center M - raised
                ZStack {
                    Button(action: { selectedTab = .home }) {
                        ChromeEmblemView(size: 60)
                    }
                    .offset(y: -16)
                }
                .frame(maxWidth: .infinity)
                
                // Mileage
                navItem(.mileage)
                // More
                navItem(.more)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private func navItem(_ tab: MilliTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? MilliColor.cyan : MilliColor.textMuted)
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? MilliColor.cyan : MilliColor.textMuted)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
