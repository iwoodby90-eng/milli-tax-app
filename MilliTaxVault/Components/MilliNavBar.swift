import SwiftUI

// MARK: - MilliTab — Navigation destinations

enum MilliTab: String, CaseIterable {
    case home = "Home"
    case payouts = "Payouts"
    case mDial = "M"
    case mileage = "Mileage"
    case more = "More"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .payouts: return "arrow.down.circle.fill"
        case .mDial: return "" // Custom center button
        case .mileage: return "car.fill"
        case .more: return "ellipsis"
        }
    }

    var label: String { rawValue }
}

// MARK: - MilliNavBar — Bel Air cockpit-style bottom navigation

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    private let barHeight: CGFloat = 72
    private let mDialSize: CGFloat = 56

    var body: some View {
        ZStack(alignment: .top) {
            // Bar background — brushed titanium feel
            navBarBackground

            // Tab items
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.payouts)
                Spacer().frame(width: mDialSize + 16) // Space for center dial
                tabButton(.mileage)
                tabButton(.more)
            }
            .padding(.horizontal, MilliSpacing.lg)
            .padding(.top, 10)

            // Center M Dial — elevated chrome circle
            mDialButton
                .offset(y: -14)
        }
        .frame(height: barHeight)
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: MilliTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedTab == tab ? MilliColors.navTabActive : MilliColors.navTabInactive)
                    .shadow(color: selectedTab == tab ? .white.opacity(0.4) : .clear, radius: 4)

                Text(tab.label)
                    .font(MilliFont.label())
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
        } label: {
            ZStack {
                // Outer chrome ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "2A3A5C"),
                                Color(hex: "0F1829")
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
                                        Color.white.opacity(0.4),
                                        Color(hex: "00D4FF").opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: MilliColors.cyan.opacity(0.4), radius: 8, y: 2)

                // Inner M letterform — angular chrome
                Text("M")
                    .font(.system(size: 24, weight: .black, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "00D4FF")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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
                        Color.white.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 1)
            }
            .shadow(color: .black.opacity(0.5), radius: 12, y: -4)
    }
}
