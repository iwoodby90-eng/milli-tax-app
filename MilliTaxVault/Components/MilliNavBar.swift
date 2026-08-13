import SwiftUI

// MARK: - MilliTab — Canonical tab definition
// Used by MilliBottomBar and ContentView

enum MilliTab: Int, CaseIterable {
    case dashboard = 0  // Home tab
    case activity = 1   // Payouts tab
    case home = 2       // Center M button
    case transfers = 3  // Mileage tab
    case more = 4       // More/settings tab
    
    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .activity: return "banknote.fill"
        case .home: return ""
        case .transfers: return "car.fill"
        case .more: return "ellipsis"
        }
    }
    
    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .activity: return "Payouts"
        case .home: return ""
        case .transfers: return "Mileage"
        case .more: return "More"
        }
    }
}

// MARK: - Legacy MilliNavBar (deprecated — use MilliBottomBar)
// Preserved for any screens still referencing it.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    
    var body: some View {
        MilliBottomBar(selectedTab: $selectedTab)
    }
}

#Preview {
    VStack {
        Spacer()
        MilliNavBar(selectedTab: .constant(.dashboard))
    }
    .background(MilliColors.obsidian)
}
