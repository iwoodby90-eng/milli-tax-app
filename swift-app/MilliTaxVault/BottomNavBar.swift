import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: AppTab
    var onCenterTap: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                
                HStack(spacing: 0) {
                    TabButton(icon: "house.fill", label: "Home", isSelected: selectedTab == .home) {
                        selectedTab = .home
                    }
                    
                    TabButton(icon: "doc.text.fill", label: "Payouts", isSelected: selectedTab == .payouts) {
                        selectedTab = .payouts
                    }
                    
                    CenterMButton(action: onCenterTap)
                    
                    TabButton(icon: "car.fill", label: "Mileage", isSelected: selectedTab == .mileage) {
                        selectedTab = .mileage
                    }
                    
                    TabButton(icon: "ellipsis", label: "More", isSelected: selectedTab == .more) {
                        selectedTab = .more
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16)
                .frame(height: 80 + (geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16))
                .background(Color(hex: "0D0D12"))
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? .milliAccent : .milliMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct CenterMButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1A2E"))
                    .frame(width: 58, height: 58)
                    .shadow(color: Color.milliAccent.opacity(0.5), radius: 12)
                
                Circle()
                    .stroke(Color.milliAccent.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 58, height: 58)
                
                Text("M")
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .chromeGradient()
            }
        }
        .buttonStyle(.plain)
        .offset(y: -12)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.milliBackground.ignoresSafeArea()
        BottomNavBar(selectedTab: .constant(.home), onCenterTap: {})
    }
}
