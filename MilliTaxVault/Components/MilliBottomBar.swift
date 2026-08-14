import SwiftUI

// MARK: - MilliBottomBar — 1954 Bel Air Dashboard Navigation
// Visual: Sculpted brushed-titanium panel with specular chrome edge,
// concave center cradle for the M dial, physical hardware aesthetic.
// Reads as machined metal instrument panel, not software UI.
// Tabs: Home, Payouts, [M center dial], Mileage, More

struct MilliBottomBar: View {
    @Binding var selectedTab: MilliTab
    
    private let barHeight: CGFloat = MilliLayout.bottomNavHeight
    private let notchDepth: CGFloat = 26
    private let notchWidth: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .top) {
            // MARK: Layer 1 — Sculpted metal body (BelAirNavBarShape)
            BelAirNavBarShape(notchDepth: notchDepth, notchWidth: notchWidth)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2A2E33"),  // Brushed titanium highlight
                            Color(hex: "1C1F24"),  // Mid-body
                            Color(hex: "111417"),  // Lower shadow
                            Color(hex: "0A0C0F")   // Deep bottom
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: barHeight)
                .shadow(color: .black.opacity(0.7), radius: 12, x: 0, y: -4)
            
            // MARK: Layer 2 — Specular chrome edge (top contour highlight)
            BelAirSpecularEdge(notchDepth: notchDepth, notchWidth: notchWidth, thickness: 1.2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.35),
                            Color(hex: "EEF2F4").opacity(0.5),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: barHeight)
            
            // MARK: Layer 3 — Subtle brushed-metal texture overlay
            BelAirNavBarShape(notchDepth: notchDepth, notchWidth: notchWidth)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.clear,
                            Color.white.opacity(0.01),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: barHeight)
            
            // MARK: Layer 4 — Inner shadow at bottom of concave notch
            // Gives depth to the center cradle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.black.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 100, height: 50)
                .offset(y: 12)
            
            // MARK: Layer 5 — Tab icons and center M dial
            HStack(spacing: 0) {
                tabButton(.dashboard, icon: "house.fill", label: "Home")
                tabButton(.activity, icon: "banknote.fill", label: "Payouts")
                
                // Center M Dial — elevated, nested in the concave cradle
                MilliCenterMButton {
                    selectedTab = .home
                }
                .offset(y: -14)
                .frame(maxWidth: .infinity)
                
                tabButton(.transfers, icon: "car.fill", label: "Mileage")
                tabButton(.more, icon: "ellipsis", label: "More")
            }
            .padding(.horizontal, 6)
            .padding(.top, 14)
        }
        .frame(height: barHeight)
    }
    
    // MARK: - Tab Button
    @ViewBuilder
    private func tabButton(_ tab: MilliTab, icon: String, label: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                // Icon with subtle glow when selected
                ZStack {
                    if selectedTab == tab {
                        // Active glow halo
                        Circle()
                            .fill(MilliColors.cyan.opacity(0.1))
                            .frame(width: 32, height: 32)
                            .blur(radius: 4)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(
                            selectedTab == tab ? MilliColors.cyan : MilliColors.inactiveTab
                        )
                        .shadow(
                            color: selectedTab == tab ? MilliColors.cyan.opacity(0.4) : .clear,
                            radius: 4, x: 0, y: 0
                        )
                }
                .frame(height: 24)
                
                Text(label)
                    .font(MilliFont.navLabel)
                    .foregroundStyle(
                        selectedTab == tab ? MilliColors.cyan : MilliColors.inactiveTab
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        VStack {
            Spacer()
            MilliBottomBar(selectedTab: .constant(.dashboard))
        }
    }
}
