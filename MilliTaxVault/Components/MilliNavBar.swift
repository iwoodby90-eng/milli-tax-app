import SwiftUI

// MARK: - MilliTab — Navigation destinations

enum MilliTab: String, CaseIterable {
    case home = "Home"
    case payouts = "Payouts"
    case mDial = "M"
    case more = "More"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .payouts: return "dollarsign.circle.fill"
        case .mDial: return "" // Custom center button
        case .more: return "ellipsis"
        }
    }

    var label: String { rawValue }
}

// MARK: - MilliNavBar — Bel Air cockpit-style bottom navigation
// 4 tabs: Home | Payouts | [M Dial] | More
// Brushed titanium background, chrome M dial center, cyan glow active state

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    private let barHeight: CGFloat = 78
    private let mDialSize: CGFloat = 60

    var body: some View {
        ZStack(alignment: .top) {
            // Bar background — brushed titanium/blackGlass feel
            navBarBackground

            // Tab items
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.payouts)
                Spacer().frame(width: mDialSize + 24) // Space for center dial
                tabButton(.more)
            }
            .padding(.horizontal, MilliSpacing.xl)
            .padding(.top, 14)

            // Center M Dial — elevated chrome circle with cyan glow ring
            mDialButton
                .offset(y: -18)
        }
        .frame(height: barHeight)
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: MilliTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
            if tab != .mDial {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedTab == tab ? MilliColors.navTabActive : MilliColors.navTabInactive)
                    .shadow(color: selectedTab == tab ? MilliColors.cyanGlow.opacity(0.6) : .clear, radius: 6)

                Text(tab.label)
                    .font(MilliFont.caption)
                    .foregroundColor(selectedTab == tab ? MilliColors.navTabActive : MilliColors.navTabInactive)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Center M Dial

    private var mDialButton: some View {
        Button {
            onMDialTap()
            // Core Haptics feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        } label: {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(MilliColors.cyanGlow.opacity(0.12))
                    .frame(width: mDialSize + 16, height: mDialSize + 16)
                    .blur(radius: 6)

                // Chrome body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1A2A3E"),
                                Color(hex: "0A1018")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: mDialSize, height: mDialSize)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        MilliColors.cyanGlow.opacity(0.8),
                                        Color.white.opacity(0.3),
                                        MilliColors.cyanGlow.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.5), radius: 10, y: 2)

                // Inner M letterform — angular chrome with cyan glow
                Text("M")
                    .font(.system(size: 26, weight: .black, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, MilliColors.cyanGlow],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.6), radius: 4)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Background

    private var navBarBackground: some View {
        Rectangle()
            .fill(MilliColors.navBarBackground)
            .overlay(alignment: .top) {
                // Top specular edge — brushed titanium highlight
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)
            }
            .shadow(color: .black.opacity(0.6), radius: 12, y: -4)
    }
}
