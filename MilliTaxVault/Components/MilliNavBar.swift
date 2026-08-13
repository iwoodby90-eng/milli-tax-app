import SwiftUI

enum MilliTab: Int, CaseIterable {
    case dashboard, activity, home, transfers, more
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .activity: return "list.bullet"
        case .home: return ""
        case .transfers: return "arrow.2.squarepath"
        case .more: return "ellipsis"
        }
    }
    
    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .activity: return "Activity"
        case .home: return ""
        case .transfers: return "Transfers"
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
                // Dashboard
                navItem(.dashboard)
                // Activity
                navItem(.activity)
                
                // Center M sphere - raised
                ZStack {
                    Button(action: { selectedTab = .home }) {
                        mSphereView
                    }
                    .offset(y: -16)
                }
                .frame(maxWidth: .infinity)
                
                // Transfers
                navItem(.transfers)
                // More
                navItem(.more)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 16)
        }
    }
    
    private var mSphereView: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color(hex: "00E5FF"), lineWidth: 1.5)
                .frame(width: 56, height: 56)
                .shadow(color: Color(hex: "00E5FF").opacity(0.3), radius: 4)
            
            // Dark background
            Circle()
                .fill(Color(hex: "1A1F2E"))
                .frame(width: 52, height: 52)
            
            // M letter
            Text("M")
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundStyle(.white)
        }
    }
    
    @ViewBuilder
    private func navItem(_ tab: MilliTab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.dashboard))
        }
    }
}
