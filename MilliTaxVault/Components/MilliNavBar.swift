import SwiftUI
import UIKit

// MARK: - MilliTab

enum MilliTab: String, CaseIterable {
    case payouts = "Payouts"
    case mileage = "Mileage"
    case wealth = "Wealth"
    case more = "More"
    case home = "Home"

    var icon: String {
        switch self {
        case .payouts: return "creditcard.fill"
        case .mileage: return "gauge.with.dots.needle.bottom.50percent"
        case .wealth: return "chart.bar.xaxis"
        case .more: return "ellipsis.message.fill"
        case .home: return ""
        }
    }
}

// MARK: - MilliNavBar
// Production cockpit navigation bar exactly matching the approved design references (Image 22):
// - Sculpted floating pill bar with 34pt continuous corner radius & beveled metallic chrome stroke
// - Recessed dark obsidian black-glass background with ambient cyan illumination
// - Center elevated M hardware dial with concentric circular chrome bezel, 36 precision tick marks,
//   and glowing neon cyan light ring
// - 4 core tab destinations: Payouts, Mileage, Wealth, More, plus center M dial (Home)

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}
    
    @State private var isDialPressed = false
    @State private var glowPulse = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Ambient cyan underglow
            Capsule(style: .continuous)
                .fill(MilliColors.cyanGlow.opacity(0.18))
                .frame(height: 52)
                .blur(radius: 18)
                .padding(.horizontal, 24)
                .offset(y: -4)
            
            // Cockpit floating bar background
            cockpitBarBody
            
            // Center M dial button
            centerDialButton
                .offset(y: -22)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 94)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
    
    // MARK: - Cockpit Floating Bar Body
    
    private var cockpitBarBody: some View {
        ZStack {
            // Recessed obsidian glass chassis
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "101418"),
                            Color(hex: "07090B"),
                            Color(hex: "030507")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Chrome beveled edge stroke
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.70), location: 0.0),
                            .init(color: Color(hex: "8E96A0").opacity(0.50), location: 0.25),
                            .init(color: MilliColors.cyanGlow.opacity(0.35), location: 0.50),
                            .init(color: Color(hex: "252B34").opacity(0.80), location: 0.75),
                            .init(color: Color.white.opacity(0.30), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
            
            // Tab button destinations
            HStack(spacing: 0) {
                // Left group: Payouts & Mileage
                tabButton(.payouts)
                tabButton(.mileage)
                
                // Gap for center dial
                Spacer()
                    .frame(width: 76)
                
                // Right group: Wealth & More
                tabButton(.wealth)
                tabButton(.more)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 68)
        .shadow(color: Color.black.opacity(0.85), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Tab Item Button
    
    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                // Icon with active glowing pill / tint
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MilliColors.cyanGlow.opacity(0.30),
                                        MilliColors.cyanGlow.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 32, height: 32)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(
                            isSelected ?
                            AnyShapeStyle(MilliColors.cyanGlow) :
                            AnyShapeStyle(Color(hex: "8A939E"))
                        )
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.65) : .clear, radius: 4)
                }
                .frame(height: 24)
                
                // Label
                Text(tab.rawValue)
                    .font(.custom("Inter-Medium", size: 10, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "7E8794"))
                    .tracking(0.2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Center Elevated M Dial (Home)
    
    private var centerDialButton: some View {
        let isHome = selectedTab == .home
        
        return Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                selectedTab = .home
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            ZStack {
                // Outer chrome hardware bezel
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "E8ECEF"),
                                Color(hex: "6A727C"),
                                Color(hex: "D8DEE4"),
                                Color(hex: "2B313A"),
                                Color(hex: "C4CBD3"),
                                Color(hex: "5D656F"),
                                Color(hex: "F2F5F8"),
                                Color(hex: "E8ECEF")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 66, height: 66)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.85), lineWidth: 0.8)
                    }
                    .shadow(color: Color.black.opacity(0.9), radius: 8, x: 0, y: 6)
                
                // Precision tick marks ring (36 ticks)
                Circle()
                    .fill(Color(hex: "05080B"))
                    .frame(width: 58, height: 58)
                
                ForEach(0..<36, id: \.self) { index in
                    Capsule()
                        .fill(index % 6 == 0 ? Color.white.opacity(0.85) : MilliColors.cyanGlow.opacity(0.6))
                        .frame(width: 1.0, height: index % 6 == 0 ? 4.5 : 3.0)
                        .offset(y: -26)
                        .rotationEffect(.degrees(Double(index) * 10))
                }
                
                // Cyan illuminated light ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                MilliColors.cyanGlow,
                                Color(hex: "00B4D8"),
                                MilliColors.cyanGlow.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.8
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: MilliColors.cyanGlow.opacity(glowPulse ? 0.85 : 0.55), radius: glowPulse ? 6 : 3)
                
                // Inner dark face
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "12171E"),
                                Color(hex: "070A0D"),
                                Color.black
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 24
                        )
                    )
                    .frame(width: 47, height: 47)
                
                // Canonical M metallic logo with cyan blade
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .blendMode(.screen)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 5)
            }
            .scaleEffect(isDialPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isDialPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isDialPressed = true }
                .onEnded { _ in isDialPressed = false }
        )
        .accessibilityLabel("Home")
        .accessibilityHint("Navigates to the Milli Home cockpit")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()
        
        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.home))
        }
    }
}
