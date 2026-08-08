import SwiftUI
import UIKit

// MARK: - App Tab Enum
enum AppTab: Equatable {
    case vault, wealth, home, activity, cockpit
}

// MARK: - Blur Background (native UIKit blur)
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Bel Air Nav Bar
struct BelAirNavBar: View {
    @Binding var selectedTab: AppTab
    @State private var mDialPressed = false
    @State private var mDialGlow = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Native blur background — real glass, not fake
            BlurView(style: .systemUltraThinMaterialDark)
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    // Top chrome specularity line
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        Spacer()
                    }
                )
                .overlay(
                    // Subtle dark tint
                    LinearGradient(
                        colors: [Color.black.opacity(0.45), Color.black.opacity(0.25)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 0) {
                    // LEFT: Vault
                    NavTabButton(
                        icon: "lock.rectangle.stack.fill",
                        label: "Vault",
                        tab: .vault,
                        selectedTab: $selectedTab
                    )
                    
                    // LEFT: Wealth
                    NavTabButton(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Wealth",
                        tab: .wealth,
                        selectedTab: $selectedTab
                    )
                    
                    // CENTER: M Dial — the crown jewel
                    MDial(selectedTab: $selectedTab, isPressed: $mDialPressed, isGlowing: $mDialGlow)
                        .frame(width: 80)
                        .offset(y: -22)
                    
                    // RIGHT: Activity
                    NavTabButton(
                        icon: "waveform.path.ecg",
                        label: "Activity",
                        tab: .activity,
                        selectedTab: $selectedTab
                    )
                    
                    // RIGHT: Cockpit
                    NavTabButton(
                        icon: "dial.medium.fill",
                        label: "Cockpit",
                        tab: .cockpit,
                        selectedTab: $selectedTab
                    )
                }
                .padding(.top, 12)
                .padding(.horizontal, 8)
                
                // Safe area spacer
                Spacer(minLength: 0)
                    .frame(height: safeAreaBottom)
            }
        }
        .frame(height: 72 + safeAreaBottom)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                mDialGlow = true
            }
        }
    }
    
    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - M Dial (the center home button)
struct MDial: View {
    @Binding var selectedTab: AppTab
    @Binding var isPressed: Bool
    @Binding var isGlowing: Bool
    
    var isHome: Bool { selectedTab == .home }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                isPressed = true
                selectedTab = .home
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                // LAYER 1: Outer glow ring (when home is active)
                if isHome {
                    Circle()
                        .fill(Color(hex: "00B4FF").opacity(isGlowing ? 0.20 : 0.08))
                        .frame(width: 88, height: 88)
                        .blur(radius: 8)
                }
                
                // LAYER 2: Chrome outer bezel
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "6A6A6A"),
                                Color(hex: "CCCCCC"),
                                Color(hex: "4A4A4A"),
                                Color(hex: "AAAAAA"),
                                Color(hex: "555555"),
                                Color(hex: "BBBBBB"),
                                Color(hex: "6A6A6A")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.black.opacity(0.7), radius: 8, x: 0, y: 4)
                    .shadow(color: Color.white.opacity(0.1), radius: 2, x: 0, y: -1)
                
                // LAYER 3: Inner dark well
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "2A2A2A"),
                                Color(hex: "111111"),
                                Color(hex: "0A0A0A")
                            ],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                
                // LAYER 4: M lettermark with chrome gradient
                Text("M")
                    .font(.system(size: 28, weight: .black, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: isHome
                                ? [Color(hex: "7ADEFD"), Color(hex: "FFFFFF"), Color(hex: "00B4FF"), Color(hex: "FFFFFF")]
                                : [Color(hex: "AAAAAA"), Color(hex: "EEEEEE"), Color(hex: "999999")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: isHome ? Color(hex: "00B4FF").opacity(0.8) : Color.clear, radius: 6)
                
                // LAYER 5: Cyan runway accent stripe (active only)
                if isHome {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00B4FF"), Color(hex: "7ADEFD")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 28, height: 2.5)
                        .shadow(color: Color(hex: "00B4FF"), radius: 6)
                        .offset(y: 25)
                }
                
                // LAYER 6: Top specular highlight
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 32, height: 14)
                    .offset(y: -18)
                    .blur(radius: 2)
            }
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Individual Nav Tab Button
struct NavTabButton: View {
    let icon: String
    let label: String
    let tab: AppTab
    @Binding var selectedTab: AppTab
    
    var isSelected: Bool { selectedTab == tab }
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 3) {
                ZStack {
                    // Active indicator background
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "00B4FF").opacity(0.12))
                            .frame(width: 36, height: 28)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected
                            ? LinearGradient(
                                colors: [Color(hex: "00B4FF"), Color(hex: "7ADEFD")],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                            : LinearGradient(
                                colors: [Color(hex: "6B6B7A"), Color(hex: "5A5A68")],
                                startPoint: .top,
                                endPoint: .bottom
                              )
                        )
                        .shadow(color: isSelected ? Color(hex: "00B4FF").opacity(0.5) : Color.clear, radius: 4)
                }
                .frame(height: 28)
                
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular, design: .default))
                    .foregroundColor(isSelected ? Color(hex: "00B4FF") : Color(hex: "5A5A68"))
                    .tracking(isSelected ? 0.3 : 0)
                
                // Active dot indicator
                Circle()
                    .fill(isSelected ? Color(hex: "00B4FF") : Color.clear)
                    .frame(width: 3, height: 3)
                    .shadow(color: isSelected ? Color(hex: "00B4FF") : Color.clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
