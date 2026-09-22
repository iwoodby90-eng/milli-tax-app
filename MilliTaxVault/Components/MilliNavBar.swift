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
        case .vault: return "wallet.pass.fill"
        case .activity: return "safari"
        case .wealth: return "chart.bar.fill"
        case .cockpit: return "ellipsis"
        case .home: return ""
        }
    }

    var displayName: String {
        switch self {
        case .vault: return "Payouts"
        case .activity: return "Mileage"
        case .wealth: return "Wealth"
        case .cockpit: return "More"
        case .home: return "Home"
        }
    }
}

// MARK: - MilliNavBar
// Renders the approved chrome navigation deck artwork. The artwork carries the
// chassis, the black glass fascia and the seated M dial; the tab glyphs, labels
// and hit targets are live SwiftUI laid out on the artwork's own geometry.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false
    @ObservedObject private var companion = MilliCompanionDirector.shared

    /// Intrinsic aspect ratio of `milli-nav-deck`.
    private let deckAspect: CGFloat = 981.0 / 290.0
    private let safeAreaExtension: CGFloat = 44

    /// Horizontal centers of the four tab columns within the deck artwork.
    private let columnCenters: [MilliTab: CGFloat] = [
        .vault: 0.143,
        .activity: 0.299,
        .wealth: 0.699,
        .cockpit: 0.852
    ]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = width / deckAspect

            ZStack(alignment: .topLeading) {
                Image("milli-nav-deck")
                    .resizable()
                    .scaledToFit()
                    .frame(width: width, height: height)
                    .allowsHitTesting(false)

                ForEach(MilliTab.allCases.filter { columnCenters[$0] != nil }, id: \.self) { tab in
                    tabButton(tab, height: height)
                        .frame(width: width * 0.15, height: height * 0.62)
                        .position(
                            x: width * (columnCenters[tab] ?? 0.5),
                            y: height * 0.63
                        )
                }

                centerDialButton(size: width * 0.238)
                    .position(x: width * 0.5, y: height * 0.44)

                if let milestone = companion.celebration {
                    MilliDialCelebration(milestone: milestone, dialSize: width * 0.238) {
                        companion.dismissCelebration()
                    }
                    .position(x: width * 0.5, y: height * 0.44)
                }

                MilliNavWalker(
                    deckWidth: width,
                    deckHeight: height,
                    isWalking: companion.isStrolling && companion.celebration == nil
                )
            }
            .frame(width: width, height: height)
        }
        .aspectRatio(deckAspect, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.black)
                .frame(height: safeAreaExtension)
                .offset(y: safeAreaExtension - 2)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Milli navigation")
    }

    // MARK: - Tab Item Button

    private func tabButton(_ tab: MilliTab, height: CGFloat) -> some View {
        let isSelected = selectedTab == tab
        let badgeSize = height * 0.30
        let labelSize = max(9.0, height * 0.088)

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: height * 0.055) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [MilliColors.cyan, MilliColors.deepCyan],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "C9CFD6"), Color(hex: "8C949C")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .frame(width: badgeSize, height: badgeSize)
                        .shadow(
                            color: isSelected
                                ? MilliColors.cyanGlow.opacity(0.55)
                                : Color.black.opacity(0.6),
                            radius: isSelected ? 7 : 3,
                            y: 1
                        )

                    Image(systemName: tab.icon)
                        .font(.system(size: badgeSize * 0.52, weight: .bold))
                        .foregroundStyle(Color(hex: "07090B"))
                }

                Text(tab.displayName)
                    .font(.custom("Inter-SemiBold", size: labelSize, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "C3C9D0"))
                    .tracking(0.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Center M Dial
    // The dial is drawn by the deck artwork; this is its live hit target.

    private func centerDialButton(size: CGFloat) -> some View {
        Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            Circle()
                .fill(Color.white.opacity(isDialPressed ? 0.10 : 0.001))
                .frame(width: size, height: size)
                .contentShape(Circle())
                .scaleEffect(isDialPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isDialPressed)
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
            MilliNavBar(selectedTab: .constant(.vault))
        }
    }
}
