import SwiftUI

// MARK: - MilliTab — Canonical tab definition
enum MilliTab: Int, CaseIterable {
    case dashboard = 0  // Home tab
    case activity = 1   // Payouts tab
    case home = 2       // Center M button (Home)
    case wealth = 3     // Wealth tab
    case transfers = 4  // Mileage tab

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .activity: return "banknote.fill"
        case .home: return ""
        case .wealth: return "chart.line.uptrend.xyaxis"
        case .transfers: return "car.fill"
        }
    }

    var label: String {
        switch self {
        case .dashboard: return "Home"
        case .activity: return "Payouts"
        case .home: return ""
        case .wealth: return "Wealth"
        case .transfers: return "Mileage"
        }
    }
}

// MARK: - MilliNavBar — Brushed Polished Nickel Automotive Dashboard
// Thick metallic panel with recessed pill-well buttons and raised chrome M dial
struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab

    // Brushed nickel gradient stops
    private let nickelGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "C8CAC8"), location: 0.0),
            .init(color: Color(hex: "8E9296"), location: 0.25),
            .init(color: Color(hex: "6E7478"), location: 0.5),
            .init(color: Color(hex: "8E9296"), location: 0.75),
            .init(color: Color(hex: "B4B6B4"), location: 1.0),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private let leftTabs: [MilliTab] = [.dashboard, .activity]
    private let rightTabs: [MilliTab] = [.wealth, .transfers]

    var body: some View {
        ZStack(alignment: .top) {
            // Base metallic panel
            VStack(spacing: 0) {
                // Specular top edge
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(height: 1)

                // Main brushed nickel surface
                ZStack {
                    // Metal gradient fill
                    nickelGradient

                    // Horizontal brush-line texture
                    BrushLineCanvas()
                        .opacity(0.06)
                }
                .frame(height: 90)

                // Bottom edge shadow
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 2)

                // Home indicator safe area (match metal)
                nickelGradient
                    .frame(height: 34)
            }

            // Tab buttons overlay
            HStack(spacing: 0) {
                // Left tabs
                ForEach(leftTabs, id: \.rawValue) { tab in
                    TabPillButton(tab: tab, isActive: selectedTab == tab) {
                        selectedTab = tab
                    }
                }

                // Center M Dial — raised above surface
                MDialButton {
                    selectedTab = .home
                }
                .offset(y: -28)

                // Right tabs
                ForEach(rightTabs, id: \.rawValue) { tab in
                    TabPillButton(tab: tab, isActive: selectedTab == tab) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 18)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Brush Line Canvas Texture
struct BrushLineCanvas: View {
    var body: some View {
        Canvas { context, size in
            let lineCount = 40
            let spacing = size.height / CGFloat(lineCount)
            for i in 0..<lineCount {
                let y = CGFloat(i) * spacing + spacing * 0.5
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.white), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - TabPillButton — Recessed oval well
struct TabPillButton: View {
    let tab: MilliTab
    let isActive: Bool
    let action: () -> Void

    private let cyanColor = Color(hex: "00E5FF")

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isActive ? cyanColor : .white)
                    .shadow(color: isActive ? cyanColor.opacity(0.7) : .clear, radius: 6, x: 0, y: 0)

                Text(tab.label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(isActive ? cyanColor : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.4),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
                    .shadow(color: .white.opacity(0.12), radius: 1, x: -1, y: -1)
            )
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MDialButton — Raised Chrome Circle (Center Home)
struct MDialButton: View {
    let action: () -> Void

    private let cyanColor = Color(hex: "00E5FF")

    var body: some View {
        Button(action: action) {
            ZStack {
                // Cyan tick-mark ring (gauge bezel)
                Circle()
                    .strokeBorder(
                        cyanColor.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
                    .frame(width: 76, height: 76)

                // Outer chrome ring
                Circle()
                    .stroke(
                        RadialGradient(
                            colors: [Color(hex: "E8EAEA"), Color(hex: "5A5E62")],
                            center: .top,
                            startRadius: 0,
                            endRadius: 36
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 72, height: 72)

                // Inner face — subtle dome
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "2A2A2C"), Color(hex: "1A1A1C")],
                            center: .center,
                            startRadius: 0,
                            endRadius: 34
                        )
                    )
                    .frame(width: 68, height: 68)

                // Angular M logo
                Text("M")
                    .font(.system(size: 28, weight: .heavy, design: .default))
                    .foregroundStyle(cyanColor)
                    .shadow(color: Color.black.opacity(0.6), radius: 2, x: 1, y: 2)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 80)
    }
}

#Preview {
    ZStack {
        Color(hex: "0A0A0C").ignoresSafeArea()
        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.dashboard))
        }
    }
}
