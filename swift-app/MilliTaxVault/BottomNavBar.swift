import SwiftUI

struct BelAirNavBar: View {
    @Binding var selectedTab: AppTab
    @State private var mDialPressed = false
    
    private var bottomSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background — brushed titanium / chrome panel
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1C1C1E"),
                            Color(hex: "2C2C2E"),
                            Color(hex: "1C1C1E")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 20, x: 0, y: -4)
                .frame(height: 90 + bottomSafeArea)
            
            HStack(alignment: .center, spacing: 0) {
                // Left tabs
                NavTabItem(icon: "lock.fill", label: "Vault", tab: .vault, selectedTab: $selectedTab)
                NavTabItem(icon: "chart.bar.fill", label: "Wealth", tab: .wealth, selectedTab: $selectedTab)
                
                // CENTER M DIAL
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        mDialPressed = true
                        selectedTab = .home
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        mDialPressed = false
                    }
                }) {
                    ZStack {
                        // Outer chrome ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "4A4A4A"), Color(hex: "1A1A1A")],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 34
                                )
                            )
                            .frame(width: 68, height: 68)
                            .overlay(
                                Circle().stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                            )
                            .shadow(color: Color(hex: "00B4FF").opacity(selectedTab == .home ? 0.6 : 0.2), radius: 16, x: 0, y: 0)
                        
                        // Inner chrome bezel
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "3A3A3A"), Color(hex: "111111")],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 28
                                )
                            )
                            .frame(width: 54, height: 54)
                        
                        // M lettermark — angular chrome
                        Text("M")
                            .font(.system(size: 26, weight: .black, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: selectedTab == .home ?
                                        [Color(hex: "00B4FF"), Color.white, Color(hex: "00B4FF")] :
                                        [Color.white.opacity(0.9), Color(hex: "8B8BA0"), Color.white.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Cyan runway accent — bottom of dial
                        if selectedTab == .home {
                            Capsule()
                                .fill(Color(hex: "00B4FF"))
                                .frame(width: 24, height: 3)
                                .offset(y: 22)
                                .shadow(color: Color(hex: "00B4FF"), radius: 4)
                        }
                    }
                    .scaleEffect(mDialPressed ? 0.92 : 1.0)
                    .offset(y: -18)
                }
                Spacer()
                
                // Right tabs
                NavTabItem(icon: "bolt.fill", label: "Activity", tab: .activity, selectedTab: $selectedTab)
                NavTabItem(icon: "slider.horizontal.3", label: "Cockpit", tab: .cockpit, selectedTab: $selectedTab)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, bottomSafeArea + 8)
            .frame(height: 80)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NavTabItem: View {
    let icon: String
    let label: String
    let tab: AppTab
    @Binding var selectedTab: AppTab
    
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(
                        isSelected ?
                            LinearGradient(colors: [Color(hex: "00B4FF"), Color(hex: "0099DD")], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [Color(hex: "8B8BA0"), Color(hex: "8B8BA0")], startPoint: .top, endPoint: .bottom)
                    )
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "00B4FF") : Color(hex: "8B8BA0"))
                
                if isSelected {
                    Capsule()
                        .fill(Color(hex: "00B4FF"))
                        .frame(width: 16, height: 2)
                        .shadow(color: Color(hex: "00B4FF"), radius: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.milliBackground.ignoresSafeArea()
        BelAirNavBar(selectedTab: .constant(.home))
    }
}
