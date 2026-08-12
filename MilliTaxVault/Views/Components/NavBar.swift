import SwiftUI

struct NavBar: View {
    @Binding var selectedTab: MilliTab
    
    var body: some View {
        HStack(spacing: 0) {
            // Left tabs: Vault, Wealth
            tabButton(for: .vault)
            tabButton(for: .wealth)
            
            // Center M button
            centerMButton
            
            // Right tabs: Activity, Cockpit
            tabButton(for: .activity)
            tabButton(for: .cockpit)
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Tab Button
    
    private func tabButton(for tab: MilliTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedTab == tab ? MilliColors.cyan : MilliColors.inactiveTab)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(selectedTab == tab ? MilliColors.cyan : MilliColors.inactiveTab)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Center M Button
    
    private var centerMButton: some View {
        Button {
            // M button returns to Vault (home)
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = .vault
            }
        } label: {
            ZStack {
                Circle()
                    .fill(MilliGradients.mButton)
                    .frame(width: 62, height: 62)
                
                Text("M")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(MilliGradients.mButtonText)
                
                Circle()
                    .stroke(MilliGradients.mButtonStroke, lineWidth: 1.5)
                    .frame(width: 62, height: 62)
            }
            .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
            .offset(y: -16)
        }
        .frame(maxWidth: .infinity)
    }
}
