import SwiftUI
import UIKit

// MARK: - App Tab Enum

enum AppTab: Equatable {
    case vault, payouts, home, mileage, more
}

// MARK: - Blur Background

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// MARK: - Angular M Shape (logo lettermark)

struct AngularMShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height
        let stroke: CGFloat = w * 0.18
        // Left vertical
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: stroke, y: 0))
        path.addLine(to: CGPoint(x: stroke, y: h * 0.55))
        // Left diagonal down to V center
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
        // Right diagonal up from V center
        path.addLine(to: CGPoint(x: w - stroke, y: h * 0.55))
        path.addLine(to: CGPoint(x: w - stroke, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w - stroke, y: h))
        path.addLine(to: CGPoint(x: w - stroke, y: h * 0.72))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))
        path.addLine(to: CGPoint(x: stroke, y: h * 0.72))
        path.addLine(to: CGPoint(x: stroke, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Bel Air Nav Bar

struct BelAirNavBar: View {
    @Binding var selectedTab: AppTab
    @State private var mDialPressed = false
    @State private var mDialGlow = false

    var body: some View {
        ZStack(alignment: .top) {
            // Blur background
            BlurView(style: .systemUltraThinMaterialDark)
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    VStack(spacing: 0) {
                        // Chrome specularity line at top
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 1)
                        Spacer()
                    }
                )
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.5), Color.black.opacity(0.25)],
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

                    // LEFT: Payouts
                    NavTabButton(
                        icon: "arrow.down.circle.fill",
                        label: "Payouts",
                        tab: .payouts,
                        selectedTab: $selectedTab
                    )

                    // CENTER: M Dial
                    MDialButton(selectedTab: $selectedTab, isPressed: $mDialPressed, isGlowing: $mDialGlow)
                        .frame(width: 80)
                        .offset(y: -14)

                    // RIGHT: Mileage
                    NavTabButton(
                        icon: "car.fill",
                        label: "Mileage",
                        tab: .mileage,
                        selectedTab: $selectedTab
                    )

                    // RIGHT: More
                    NavTabButton(
                        icon: "ellipsis",
                        label: "More",
                        tab: .more,
                        selectedTab: $selectedTab
                    )
                }
                .padding(.top, 12)
                .padding(.horizontal, 8)

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

// MARK: - M Dial Button (center home)

struct MDialButton: View {
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
                // LAYER 1: Outer glow (active)
                if isHome {
                    Circle()
                        .fill(Color.milliCyan.opacity(isGlowing ? 0.15 : 0.06))
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                }

                // LAYER 2: Chrome outer bezel (AngularGradient)
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "6A6A6A"),
                                Color(hex: "DDDDDD"),
                                Color(hex: "4A4A4A"),
                                Color(hex: "BBBBBB"),
                                Color(hex: "555555"),
                                Color(hex: "CCCCCC"),
                                Color(hex: "6A6A6A")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 54, height: 54)
                    .shadow(color: Color.black.opacity(0.7), radius: 6, x: 0, y: 3)
                    .shadow(color: Color.white.opacity(0.08), radius: 2, x: 0, y: -1)

                // LAYER 3: Dark inner well (RadialGradient)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "222222"),
                                Color(hex: "0E0E0E"),
                                Color(hex: "080808")
                            ],
                            center: .init(x: 0.4, y: 0.35),
                            startRadius: 0,
                            endRadius: 22
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )

                // LAYER 4: Angular M lettermark
                AngularMShape()
                    .fill(
                        LinearGradient(
                            colors: isHome
                                ? [Color(hex: "7ADEFD"), Color.white, Color(hex: "00B4FF"), Color.white]
                                : [Color(hex: "AAAAAA"), Color(hex: "EEEEEE"), Color(hex: "999999")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 18, height: 20)
                    .shadow(color: isHome ? Color.milliCyan.opacity(0.7) : Color.clear, radius: 5)

                // LAYER 5: Top specular highlight
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 24, height: 10)
                    .offset(y: -14)
                    .blur(radius: 1.5)
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Nav Tab Button

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
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.milliCyan : Color.milliTextTertiary)
                    .shadow(color: isSelected ? Color.milliCyan.opacity(0.5) : Color.clear, radius: 4)
                    .frame(height: 24)

                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color.milliCyan : Color.milliTextTertiary)
                    .tracking(isSelected ? 0.3 : 0)

                // Active dot
                Circle()
                    .fill(isSelected ? Color.milliCyan : Color.clear)
                    .frame(width: 3, height: 3)
                    .shadow(color: isSelected ? Color.milliCyan : Color.clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
