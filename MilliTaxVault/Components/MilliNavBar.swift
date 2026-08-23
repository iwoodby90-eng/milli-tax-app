import SwiftUI
import UIKit

// MARK: - MilliTab

enum MilliTab: String, CaseIterable {
    case vault = "Vault"
    case activity = "Activity"
    case wealth = "Wealth"
    case cockpit = "Cockpit"
    case home = "Home"

    var icon: String {
        switch self {
        case .vault: return "lock.shield.fill"
        case .activity: return "waveform.path.ecg"
        case .wealth: return "chart.bar.xaxis"
        case .cockpit: return "gauge.open.with.lines.needle.33percent"
        case .home: return ""
        }
    }
}

// MARK: - MilliNavBar
// Production cockpit navigation bar exactly matching the approved design references (Image 23):
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
    @State private var pulseStreaks = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Ambient cyan underglow aura
            Capsule(style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            MilliColors.cyanGlow.opacity(glowPulse ? 0.32 : 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 110
                    )
                )
                .frame(height: 54)
                .blur(radius: 20)
                .padding(.horizontal, 24)
                .offset(y: -4)
            
            // Cockpit floating bar background
            cockpitBarBody
            
            // Center M dial button
            centerDialButton
                .offset(y: -24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 94)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                pulseStreaks = true
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
                        stops: [
                            .init(color: Color(hex: "13181F"), location: 0.0),
                            .init(color: Color(hex: "080B0E"), location: 0.35),
                            .init(color: Color(hex: "030507"), location: 0.85),
                            .init(color: Color.black, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Subtle internal glass reflection highlight
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.09), location: 0.0),
                            .init(color: Color.white.opacity(0.02), location: 0.25),
                            .init(color: Color.clear, location: 0.50)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // High-precision beveled chrome edge stroke
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.85), location: 0.0),
                            .init(color: Color(hex: "A0AAB6").opacity(0.60), location: 0.20),
                            .init(color: MilliColors.cyanGlow.opacity(0.40), location: 0.50),
                            .init(color: Color(hex: "252B34").opacity(0.80), location: 0.80),
                            .init(color: Color.white.opacity(0.45), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
            
            // Tab button destinations
            HStack(spacing: 0) {
                // Left group: Vault & Activity
                tabButton(.vault)
                tabButton(.activity)
                
                // Center clearance for elevated hardware dial
                Spacer()
                    .frame(width: 80)
                
                // Right group: Wealth & Cockpit
                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 68)
        .shadow(color: Color.black.opacity(0.90), radius: 18, x: 0, y: 10)
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
            VStack(spacing: 3) {
                // Icon with active glowing pill / tint
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MilliColors.cyanGlow.opacity(0.35),
                                        MilliColors.cyanGlow.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 34, height: 34)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(
                            isSelected ?
                            AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.white, MilliColors.cyanGlow],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            ) :
                            AnyShapeStyle(Color(hex: "959EA9"))
                        )
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.75) : .clear, radius: 5)
                }
                .frame(height: 24)
                
                // Label
                Text(tab.rawValue)
                    .font(.custom("Inter-Medium", size: 10, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "8A939E"))
                    .tracking(0.3)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.40) : .clear, radius: 3)
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
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                selectedTab = .home
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            ZStack {
                // Outer ambient cyan glow halo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MilliColors.cyanGlow.opacity(glowPulse ? 0.45 : 0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 46
                        )
                    )
                    .frame(width: 84, height: 84)
                
                // Outer chrome hardware bezel
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "F4F7FA"),
                                Color(hex: "757D87"),
                                Color(hex: "DFE4EA"),
                                Color(hex: "2F353F"),
                                Color(hex: "CBD2DA"),
                                Color(hex: "666E78"),
                                Color(hex: "F8FAFC"),
                                Color(hex: "F4F7FA")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.90), lineWidth: 0.9)
                    }
                    .shadow(color: Color.black.opacity(0.95), radius: 10, x: 0, y: 7)
                
                // Precision tick marks ring (36 ticks)
                Circle()
                    .fill(Color(hex: "05080B"))
                    .frame(width: 60, height: 60)
                
                ForEach(0..<36, id: \.self) { index in
                    Capsule()
                        .fill(index % 6 == 0 ? Color.white.opacity(0.90) : MilliColors.cyanGlow.opacity(0.65))
                        .frame(width: index % 6 == 0 ? 1.2 : 0.9, height: index % 6 == 0 ? 4.8 : 3.2)
                        .offset(y: -27)
                        .rotationEffect(.degrees(Double(index) * 10))
                }
                
                // Cyan illuminated light ring with high-tech energy gradient
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white,
                                MilliColors.cyanGlow,
                                Color(hex: "00B4D8"),
                                Color(hex: "0077B6"),
                                MilliColors.cyanGlow.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
                    .frame(width: 51, height: 51)
                    .shadow(color: MilliColors.cyanGlow.opacity(glowPulse ? 0.95 : 0.65), radius: glowPulse ? 8 : 4)
                
                // Inner dark face
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "141A22"),
                                Color(hex: "080B0E"),
                                Color.black
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 25
                        )
                    )
                    .frame(width: 48, height: 48)
                
                // Canonical M metallic logo with cyan blade
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.60), radius: 6)
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
