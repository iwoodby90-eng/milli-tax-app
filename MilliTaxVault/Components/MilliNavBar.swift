import SwiftUI
import UIKit

// MARK: - MilliTab

enum MilliTab: String, CaseIterable {
    case home = "Home"
    case payouts = "Payouts"
    case mileage = "Mileage"
    case wealth = "Wealth"
    case more = "More"
    case mDial = "M"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .payouts: return "doc.text.fill"
        case .mileage: return "location.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"
        case .more: return "ellipsis"
        case .mDial: return ""
        }
    }
}

// MARK: - MilliNavBar
// Signature navigation inspired by a sculpted 1950s instrument panel: a recessed
// graphite tray, chrome tail-fin sweeps, and the canonical center M as HOME.
// The center M is never a secondary action and should never be replaced by TabView.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    @State private var mDriftX: CGFloat = 0
    @State private var mDriftY: CGFloat = 0
    @State private var mDriftRotation: Double = 0
    @State private var homePulse = false

    private let commandSize: CGFloat = 88
    private let shellHeight: CGFloat = MilliSpacing.bottomNavHeight

    var body: some View {
        ZStack(alignment: .top) {
            navigationTray
            underBridgeShadow
            chromeBridge
            sideDestinations
            commandDock
        }
        .frame(height: shellHeight)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityElement(children: .contain)
        .task {
            await animateCenterMarkOccasionally()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                homePulse = true
            }
        }
    }

    private var navigationTray: some View {
        MilliNavigationTrayShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "12191F"), location: 0.00),
                        .init(color: Color(hex: "090D10"), location: 0.42),
                        .init(color: Color(hex: "020405"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                MilliNavigationTrayShape()
                    .stroke(Color.white.opacity(0.075), lineWidth: 0.7)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.055), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 38)
                .mask(MilliNavigationTrayShape())
            }
            .shadow(color: .black.opacity(0.92), radius: 18, x: 0, y: -5)
    }

    private var underBridgeShadow: some View {
        MilliNavigationBridgeShape()
            .stroke(Color.black.opacity(0.84), lineWidth: 5.5)
            .blur(radius: 4.5)
            .offset(y: 4)
    }

    private var chromeBridge: some View {
        ZStack {
            MilliNavigationBridgeShape()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "20262B"), location: 0.00),
                            .init(color: MilliColors.chromeWhite, location: 0.13),
                            .init(color: Color(hex: "7C868D"), location: 0.34),
                            .init(color: MilliColors.chromeWhite, location: 0.51),
                            .init(color: Color(hex: "687178"), location: 0.72),
                            .init(color: MilliColors.chromeDeep, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliNavigationBridgeShape()
                        .stroke(Color.white.opacity(0.64), lineWidth: 0.72)
                }

            MilliNavigationBridgeHighlightShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            MilliColors.cyanGlow.opacity(0.22),
                            Color.white.opacity(0.98),
                            MilliColors.cyanGlow.opacity(0.30),
                            Color.white.opacity(0.92),
                            MilliColors.cyanGlow.opacity(0.22)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.15, lineCap: .round)
                )

            MilliNavigationBridgeHighlightShape()
                .stroke(MilliColors.cyanGlow.opacity(0.12), lineWidth: 2.4)
                .blur(radius: 2.8)
        }
        .shadow(color: .black.opacity(0.82), radius: 4, y: 3)
        .shadow(color: MilliColors.cyanGlow.opacity(0.09), radius: 8, y: -1)
    }

    private var sideDestinations: some View {
        HStack(spacing: 0) {
            tabButton(.payouts)
            tabButton(.mileage)
            Spacer().frame(width: commandSize + 34)
            tabButton(.wealth)
            tabButton(.more)
        }
        .padding(.horizontal, 7)
        .padding(.top, 29)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16.5, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isSelected ? MilliColors.navTabActive : MilliColors.navTabInactive)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.55) : .clear, radius: 4)

                Text(tab.rawValue)
                    .font(.custom("Inter-Medium", size: 9.2, relativeTo: .caption2))
                    .tracking(0.12)
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : MilliColors.navTabInactive.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Capsule(style: .continuous)
                    .fill(isSelected ? MilliColors.cyanGlow : Color.clear)
                    .frame(width: 12, height: 1.5)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.58) : .clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var commandDock: some View {
        let isHome = selectedTab == .home || selectedTab == .mDial

        return Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onMDialTap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.92))
                    .frame(width: commandSize + 24, height: commandSize + 24)
                    .overlay { Circle().stroke(Color.white.opacity(0.06), lineWidth: 1) }
                    .shadow(color: .black.opacity(0.95), radius: 13, y: 7)

                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                MilliColors.chromeDeep,
                                MilliColors.chromeWhite,
                                Color(hex: "7B858C"),
                                MilliColors.chromeWhite,
                                MilliColors.chromeDark,
                                MilliColors.chromeWhite,
                                MilliColors.chromeDeep
                            ],
                            center: .center
                        )
                    )
                    .frame(width: commandSize + 4, height: commandSize + 4)
                    .overlay { Circle().stroke(Color.white.opacity(0.64), lineWidth: 0.75) }
                    .shadow(color: Color.white.opacity(0.10), radius: 2, y: -1)

                Circle()
                    .fill(Color(hex: "020405"))
                    .frame(width: commandSize - 4, height: commandSize - 4)
                    .overlay { Circle().stroke(Color.black.opacity(0.98), lineWidth: 2.5) }

                segmentedLightRing(isHome: isHome)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "15465A"), Color(hex: "07131A"), Color.black],
                            center: UnitPoint(x: 0.48, y: 0.42),
                            startRadius: 1,
                            endRadius: 35
                        )
                    )
                    .frame(width: commandSize - 28, height: commandSize - 28)
                    .overlay { Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.75) }
                    .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.34 : 0.20), radius: isHome ? 11 : 7)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
                    .blendMode(.screen)
                    .offset(x: mDriftX, y: mDriftY)
                    .rotationEffect(.degrees(mDriftRotation))
                    .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.52 : 0.34), radius: 5)
                    .accessibilityHidden(true)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: commandSize - 34, height: commandSize - 34)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse().frame(height: 19)
                            Spacer()
                        }
                    )
                    .allowsHitTesting(false)
            }
            .frame(width: commandSize + 28, height: commandSize + 28)
        }
        .buttonStyle(MilliCommandButtonStyle())
        .offset(y: -23)
        .accessibilityLabel("Home")
        .accessibilityHint("Returns to the Milli home dashboard")
        .accessibilityAddTraits(isHome ? .isSelected : [])
    }

    private func segmentedLightRing(isHome: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(
                    MilliColors.cyanGlow.opacity(
                        isHome ? (homePulse ? 0.82 : 0.60) : 0.42
                    ),
                    lineWidth: isHome ? 2.5 : 2.1
                )
                .frame(width: commandSize - 14, height: commandSize - 14)
                .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.82 : 0.54), radius: isHome ? 8 : 5)

            Circle()
                .stroke(Color.black.opacity(0.95), lineWidth: 1.1)
                .frame(width: commandSize - 21, height: commandSize - 21)

            ForEach(0..<44, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index % 4 == 0 ? MilliColors.chromeLight : MilliColors.cyanGlow)
                    .frame(width: 1.15, height: index % 4 == 0 ? 6.2 : 4.5)
                    .offset(y: -(commandSize - 18) / 2)
                    .rotationEffect(.degrees(Double(index) * (360.0 / 44.0)))
                    .opacity(index % 4 == 0 ? 0.96 : (isHome ? 0.82 : 0.66))
            }
        }
    }

    private func animateCenterMarkOccasionally() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 3.8...6.4)))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.spring(response: 0.85, dampingFraction: 0.72)) {
                    mDriftX = CGFloat.random(in: -3.2...3.2)
                    mDriftY = CGFloat.random(in: -2.4...2.4)
                    mDriftRotation = Double.random(in: -2.1...2.1)
                }
            }

            try? await Task.sleep(for: .seconds(1.15))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 1.0)) {
                    mDriftX = 0
                    mDriftY = 0
                    mDriftRotation = 0
                }
            }
        }
    }
}

private struct MilliCommandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
            .animation(.easeOut(duration: 0.11), value: configuration.isPressed)
    }
}

// MARK: - Sculpted tail-fin shell geometry

private struct MilliNavigationTrayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX

        // Raised outer fins sweep down into the instrument panel before the center dock.
        path.move(to: CGPoint(x: 0, y: 3))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.18, y: 16),
            control1: CGPoint(x: rect.width * 0.035, y: 3),
            control2: CGPoint(x: rect.width * 0.09, y: 14)
        )
        path.addCurve(
            to: CGPoint(x: mid - 68, y: 15),
            control1: CGPoint(x: rect.width * 0.26, y: 19),
            control2: CGPoint(x: mid - 108, y: 13)
        )
        path.addCurve(to: CGPoint(x: mid - 40, y: 36), control1: CGPoint(x: mid - 56, y: 15), control2: CGPoint(x: mid - 49, y: 30))
        path.addCurve(to: CGPoint(x: mid + 40, y: 36), control1: CGPoint(x: mid - 20, y: 50), control2: CGPoint(x: mid + 20, y: 50))
        path.addCurve(to: CGPoint(x: mid + 68, y: 15), control1: CGPoint(x: mid + 49, y: 30), control2: CGPoint(x: mid + 56, y: 15))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.82, y: 16),
            control1: CGPoint(x: mid + 108, y: 13),
            control2: CGPoint(x: rect.width * 0.74, y: 19)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 3),
            control1: CGPoint(x: rect.width * 0.91, y: 14),
            control2: CGPoint(x: rect.width * 0.965, y: 3)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MilliNavigationBridgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX

        path.move(to: CGPoint(x: 0, y: 1))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.18, y: 12),
            control1: CGPoint(x: rect.width * 0.035, y: 1),
            control2: CGPoint(x: rect.width * 0.10, y: 10)
        )
        path.addCurve(
            to: CGPoint(x: mid - 67, y: 9),
            control1: CGPoint(x: rect.width * 0.29, y: 16),
            control2: CGPoint(x: mid - 105, y: 7)
        )
        path.addCurve(to: CGPoint(x: mid - 40, y: 31), control1: CGPoint(x: mid - 55, y: 9), control2: CGPoint(x: mid - 49, y: 26))
        path.addCurve(to: CGPoint(x: mid + 40, y: 31), control1: CGPoint(x: mid - 20, y: 44), control2: CGPoint(x: mid + 20, y: 44))
        path.addCurve(to: CGPoint(x: mid + 67, y: 9), control1: CGPoint(x: mid + 49, y: 26), control2: CGPoint(x: mid + 55, y: 9))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.82, y: 12),
            control1: CGPoint(x: mid + 105, y: 7),
            control2: CGPoint(x: rect.width * 0.71, y: 16)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 1),
            control1: CGPoint(x: rect.width * 0.90, y: 10),
            control2: CGPoint(x: rect.width * 0.965, y: 1)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: 15))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.82, y: 22),
            control1: CGPoint(x: rect.width * 0.96, y: 15),
            control2: CGPoint(x: rect.width * 0.90, y: 21)
        )
        path.addCurve(to: CGPoint(x: mid + 66, y: 20), control1: CGPoint(x: rect.width * 0.72, y: 24), control2: CGPoint(x: mid + 104, y: 20))
        path.addCurve(to: CGPoint(x: mid + 43, y: 39), control1: CGPoint(x: mid + 56, y: 20), control2: CGPoint(x: mid + 50, y: 35))
        path.addCurve(to: CGPoint(x: mid - 43, y: 39), control1: CGPoint(x: mid + 21, y: 53), control2: CGPoint(x: mid - 21, y: 53))
        path.addCurve(to: CGPoint(x: mid - 66, y: 20), control1: CGPoint(x: mid - 50, y: 35), control2: CGPoint(x: mid - 56, y: 20))
        path.addCurve(to: CGPoint(x: rect.width * 0.18, y: 22), control1: CGPoint(x: mid - 104, y: 20), control2: CGPoint(x: rect.width * 0.28, y: 24))
        path.addCurve(to: CGPoint(x: 0, y: 15), control1: CGPoint(x: rect.width * 0.10, y: 21), control2: CGPoint(x: rect.width * 0.04, y: 15))
        path.closeSubpath()
        return path
    }
}

private struct MilliNavigationBridgeHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX

        path.move(to: CGPoint(x: 4, y: 2))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.18, y: 11),
            control1: CGPoint(x: rect.width * 0.04, y: 2),
            control2: CGPoint(x: rect.width * 0.10, y: 9)
        )
        path.addCurve(
            to: CGPoint(x: mid - 67, y: 9),
            control1: CGPoint(x: rect.width * 0.29, y: 15),
            control2: CGPoint(x: mid - 104, y: 7)
        )
        path.addCurve(to: CGPoint(x: mid - 40, y: 31), control1: CGPoint(x: mid - 55, y: 9), control2: CGPoint(x: mid - 49, y: 26))
        path.addCurve(to: CGPoint(x: mid + 40, y: 31), control1: CGPoint(x: mid - 20, y: 44), control2: CGPoint(x: mid + 20, y: 44))
        path.addCurve(to: CGPoint(x: mid + 67, y: 9), control1: CGPoint(x: mid + 49, y: 26), control2: CGPoint(x: mid + 55, y: 9))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.82, y: 11),
            control1: CGPoint(x: mid + 104, y: 7),
            control2: CGPoint(x: rect.width * 0.71, y: 15)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - 4, y: 2),
            control1: CGPoint(x: rect.width * 0.90, y: 9),
            control2: CGPoint(x: rect.width * 0.96, y: 2)
        )
        return path
    }
}
