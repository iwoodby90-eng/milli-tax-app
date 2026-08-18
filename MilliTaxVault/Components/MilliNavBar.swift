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
// Signature cockpit navigation. The center M is HOME.
// Visual target: the same polished silver / black glass / cyan illuminated
// industrial design language as Milli AI's body rather than a flat tab bar.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    @State private var mDriftX: CGFloat = 0
    @State private var mDriftY: CGFloat = 0
    @State private var mDriftRotation: Double = 0
    @State private var homePulse = false

    private let commandSize: CGFloat = 86
    private let shellHeight: CGFloat = MilliSpacing.bottomNavHeight

    var body: some View {
        ZStack(alignment: .top) {
            navigationTray
            lowerCyanEdge
            bridgeShadow
            chromeBridge
            cyanSeam
            sideDestinations
            commandDock
        }
        .frame(height: shellHeight)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityElement(children: .contain)
        .task { await animateCenterMarkOccasionally() }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                homePulse = true
            }
        }
    }

    // MARK: Shell

    private var navigationTray: some View {
        MilliNavigationTrayShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "121920"), location: 0.00),
                        .init(color: Color(hex: "080C10"), location: 0.36),
                        .init(color: Color(hex: "030506"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                MilliNavigationTrayShape()
                    .stroke(Color.white.opacity(0.065), lineWidth: 0.65)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.055), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                .mask(MilliNavigationTrayShape())
            }
            .shadow(color: .black.opacity(0.94), radius: 20, x: 0, y: -5)
    }

    private var lowerCyanEdge: some View {
        MilliNavigationLowerEdgeShape()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.clear,
                        MilliColors.cyanGlow.opacity(0.08),
                        MilliColors.cyanGlow.opacity(0.24),
                        MilliColors.cyanGlow.opacity(0.08),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
            )
            .blur(radius: 0.3)
    }

    private var bridgeShadow: some View {
        MilliNavigationBridgeShape()
            .stroke(Color.black.opacity(0.90), lineWidth: 7)
            .blur(radius: 5)
            .offset(y: 4)
    }

    private var chromeBridge: some View {
        ZStack {
            MilliNavigationBridgeShape()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "11171B"), location: 0.00),
                            .init(color: Color(hex: "F7FAFC"), location: 0.09),
                            .init(color: Color(hex: "A7B0B6"), location: 0.22),
                            .init(color: Color(hex: "4E575D"), location: 0.43),
                            .init(color: Color(hex: "E9EDF0"), location: 0.62),
                            .init(color: Color(hex: "737D84"), location: 0.78),
                            .init(color: Color(hex: "191F23"), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliNavigationBridgeShape()
                        .stroke(Color.white.opacity(0.72), lineWidth: 0.7)
                }

            MilliNavigationBridgeHighlightShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            MilliColors.cyanGlow.opacity(0.22),
                            Color.white.opacity(0.98),
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.98),
                            MilliColors.cyanGlow.opacity(0.22)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
                )

            MilliNavigationBridgeLowerHighlightShape()
                .stroke(Color.black.opacity(0.65), lineWidth: 1.0)
                .offset(y: 0.4)
        }
        .shadow(color: .black.opacity(0.78), radius: 3.5, y: 3)
        .shadow(color: MilliColors.cyanGlow.opacity(0.08), radius: 8, y: -1)
    }

    private var cyanSeam: some View {
        MilliNavigationCyanSeamShape()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.clear,
                        MilliColors.cyanGlow.opacity(0.20),
                        MilliColors.cyanGlow.opacity(0.62),
                        MilliColors.cyanGlow.opacity(0.20),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.0, lineCap: .round)
            )
            .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 3)
    }

    // MARK: Tabs

    private var sideDestinations: some View {
        HStack(spacing: 0) {
            tabButton(.payouts)
            tabButton(.mileage)
            Spacer().frame(width: commandSize + 34)
            tabButton(.wealth)
            tabButton(.more)
        }
        .padding(.horizontal, 8)
        .padding(.top, 28)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(MilliColors.cyanGlow.opacity(0.08))
                            .frame(width: 28, height: 28)
                            .blur(radius: 3)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 16.5, weight: .semibold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(isSelected ? MilliColors.cyanGlow : MilliColors.navTabInactive)
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.60) : .clear, radius: 4)
                }
                .frame(height: 22)

                Text(tab.rawValue)
                    .font(.custom("Inter-Medium", size: 9.1, relativeTo: .caption2))
                    .tracking(0.10)
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : MilliColors.navTabInactive.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Capsule(style: .continuous)
                    .fill(isSelected ? MilliColors.cyanGlow : Color.clear)
                    .frame(width: 13, height: 1.5)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.70) : .clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: Center HOME assembly

    private var commandDock: some View {
        let isHome = selectedTab == .home || selectedTab == .mDial

        return Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onMDialTap()
        } label: {
            ZStack {
                // Mechanical outer housing.
                Circle()
                    .fill(Color.black.opacity(0.96))
                    .frame(width: commandSize + 28, height: commandSize + 28)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.07), lineWidth: 0.8)
                    }
                    .shadow(color: .black.opacity(0.96), radius: 14, y: 8)

                // Deep silver housing patterned after Milli AI's polished armor.
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "101519"),
                                Color(hex: "F9FBFC"),
                                Color(hex: "737D84"),
                                Color(hex: "DCE2E6"),
                                Color(hex: "323A40"),
                                Color(hex: "F8FAFB"),
                                Color(hex: "7A858C"),
                                Color(hex: "101519")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: commandSize + 8, height: commandSize + 8)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.72), lineWidth: 0.85)
                    }
                    .shadow(color: Color.white.opacity(0.12), radius: 2, y: -1)

                // Cyan joint ring like Milli AI shoulder/head accents.
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                MilliColors.cyanGlow.opacity(0.45),
                                MilliColors.cyanGlow,
                                Color.white.opacity(0.78),
                                MilliColors.cyanGlow,
                                MilliColors.cyanGlow.opacity(0.45)
                            ],
                            center: .center
                        ),
                        lineWidth: 2.4
                    )
                    .frame(width: commandSize - 2, height: commandSize - 2)
                    .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.78 : 0.46), radius: isHome ? 8 : 5)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "0A202A"),
                                Color(hex: "061015"),
                                Color(hex: "010203")
                            ],
                            center: UnitPoint(x: 0.46, y: 0.40),
                            startRadius: 1,
                            endRadius: 42
                        )
                    )
                    .frame(width: commandSize - 10, height: commandSize - 10)
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.98), lineWidth: 2)
                    }

                segmentedLightRing(isHome: isHome)

                // Approved canonical M only.
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .blendMode(.screen)
                    .offset(x: mDriftX, y: mDriftY)
                    .rotationEffect(.degrees(mDriftRotation))
                    .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.55 : 0.30), radius: 6)
                    .accessibilityHidden(true)

                // Convex black-glass lens highlight.
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.025), Color.clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.57)
                        )
                    )
                    .frame(width: commandSize - 18, height: commandSize - 18)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse().frame(height: 27)
                            Spacer()
                        }
                    )
                    .allowsHitTesting(false)

                // Tiny illuminated crown detail, borrowed from Milli AI's helmet light.
                Capsule(style: .continuous)
                    .fill(MilliColors.cyanGlow.opacity(isHome ? 0.95 : 0.55))
                    .frame(width: 19, height: 2.2)
                    .offset(y: -(commandSize / 2) + 7)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.65), radius: 3)
            }
            .frame(width: commandSize + 30, height: commandSize + 30)
        }
        .buttonStyle(MilliCommandButtonStyle())
        .offset(y: -22)
        .accessibilityLabel("Home")
        .accessibilityHint("Returns to the Milli home dashboard")
        .accessibilityAddTraits(isHome ? .isSelected : [])
    }

    private func segmentedLightRing(isHome: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(
                    MilliColors.cyanGlow.opacity(isHome ? (homePulse ? 0.78 : 0.58) : 0.34),
                    lineWidth: isHome ? 1.8 : 1.4
                )
                .frame(width: commandSize - 19, height: commandSize - 19)
                .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.70 : 0.38), radius: isHome ? 7 : 4)

            ForEach(0..<40, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index % 5 == 0 ? Color.white.opacity(0.92) : MilliColors.cyanGlow)
                    .frame(width: 1.0, height: index % 5 == 0 ? 5.2 : 3.8)
                    .offset(y: -(commandSize - 24) / 2)
                    .rotationEffect(.degrees(Double(index) * 9.0))
                    .opacity(index % 5 == 0 ? 0.90 : (isHome ? 0.76 : 0.48))
            }
        }
    }

    private func animateCenterMarkOccasionally() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 4.2...7.2)))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.spring(response: 0.92, dampingFraction: 0.74)) {
                    mDriftX = CGFloat.random(in: -2.5...2.5)
                    mDriftY = CGFloat.random(in: -1.8...1.8)
                    mDriftRotation = Double.random(in: -1.5...1.5)
                }
            }

            try? await Task.sleep(for: .seconds(1.2))
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
            .brightness(configuration.isPressed ? 0.055 : 0)
            .animation(.easeOut(duration: 0.11), value: configuration.isPressed)
    }
}

// MARK: - Sculpted tail-fin geometry

private struct MilliNavigationTrayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX

        path.move(to: CGPoint(x: 0, y: 6))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.17, y: 17),
            control1: CGPoint(x: rect.width * 0.035, y: 6),
            control2: CGPoint(x: rect.width * 0.09, y: 16)
        )
        path.addCurve(
            to: CGPoint(x: mid - 66, y: 15),
            control1: CGPoint(x: rect.width * 0.27, y: 20),
            control2: CGPoint(x: mid - 105, y: 13)
        )
        path.addCurve(to: CGPoint(x: mid - 39, y: 35), control1: CGPoint(x: mid - 55, y: 15), control2: CGPoint(x: mid - 48, y: 29))
        path.addCurve(to: CGPoint(x: mid + 39, y: 35), control1: CGPoint(x: mid - 20, y: 46), control2: CGPoint(x: mid + 20, y: 46))
        path.addCurve(to: CGPoint(x: mid + 66, y: 15), control1: CGPoint(x: mid + 48, y: 29), control2: CGPoint(x: mid + 55, y: 15))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.83, y: 17),
            control1: CGPoint(x: mid + 105, y: 13),
            control2: CGPoint(x: rect.width * 0.73, y: 20)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 6),
            control1: CGPoint(x: rect.width * 0.91, y: 16),
            control2: CGPoint(x: rect.width * 0.965, y: 6)
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

        // Longer, thinner Bel Air-style fins: raised at the outside, diving inward to the M.
        path.move(to: CGPoint(x: 0, y: 2))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.17, y: 10),
            control1: CGPoint(x: rect.width * 0.035, y: 2),
            control2: CGPoint(x: rect.width * 0.095, y: 9)
        )
        path.addCurve(
            to: CGPoint(x: mid - 68, y: 8),
            control1: CGPoint(x: rect.width * 0.28, y: 13),
            control2: CGPoint(x: mid - 108, y: 7)
        )
        path.addCurve(to: CGPoint(x: mid - 40, y: 29), control1: CGPoint(x: mid - 56, y: 8), control2: CGPoint(x: mid - 49, y: 24))
        path.addCurve(to: CGPoint(x: mid + 40, y: 29), control1: CGPoint(x: mid - 20, y: 41), control2: CGPoint(x: mid + 20, y: 41))
        path.addCurve(to: CGPoint(x: mid + 68, y: 8), control1: CGPoint(x: mid + 49, y: 24), control2: CGPoint(x: mid + 56, y: 8))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.83, y: 10),
            control1: CGPoint(x: mid + 108, y: 7),
            control2: CGPoint(x: rect.width * 0.72, y: 13)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: 2),
            control1: CGPoint(x: rect.width * 0.905, y: 9),
            control2: CGPoint(x: rect.width * 0.965, y: 2)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: 11))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.83, y: 18),
            control1: CGPoint(x: rect.width * 0.96, y: 11),
            control2: CGPoint(x: rect.width * 0.91, y: 17)
        )
        path.addCurve(to: CGPoint(x: mid + 67, y: 17), control1: CGPoint(x: rect.width * 0.73, y: 20), control2: CGPoint(x: mid + 104, y: 17))
        path.addCurve(to: CGPoint(x: mid + 42, y: 36), control1: CGPoint(x: mid + 56, y: 17), control2: CGPoint(x: mid + 50, y: 32))
        path.addCurve(to: CGPoint(x: mid - 42, y: 36), control1: CGPoint(x: mid + 21, y: 49), control2: CGPoint(x: mid - 21, y: 49))
        path.addCurve(to: CGPoint(x: mid - 67, y: 17), control1: CGPoint(x: mid - 50, y: 32), control2: CGPoint(x: mid - 56, y: 17))
        path.addCurve(to: CGPoint(x: rect.width * 0.17, y: 18), control1: CGPoint(x: mid - 104, y: 17), control2: CGPoint(x: rect.width * 0.27, y: 20))
        path.addCurve(to: CGPoint(x: 0, y: 11), control1: CGPoint(x: rect.width * 0.09, y: 17), control2: CGPoint(x: rect.width * 0.04, y: 11))
        path.closeSubpath()
        return path
    }
}

private struct MilliNavigationBridgeHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX

        path.move(to: CGPoint(x: 4, y: 3))
        path.addCurve(to: CGPoint(x: rect.width * 0.17, y: 9), control1: CGPoint(x: rect.width * 0.04, y: 3), control2: CGPoint(x: rect.width * 0.095, y: 8))
        path.addCurve(to: CGPoint(x: mid - 68, y: 8), control1: CGPoint(x: rect.width * 0.28, y: 12), control2: CGPoint(x: mid - 108, y: 7))
        path.addCurve(to: CGPoint(x: mid - 40, y: 29), control1: CGPoint(x: mid - 56, y: 8), control2: CGPoint(x: mid - 49, y: 24))
        path.addCurve(to: CGPoint(x: mid + 40, y: 29), control1: CGPoint(x: mid - 20, y: 41), control2: CGPoint(x: mid + 20, y: 41))
        path.addCurve(to: CGPoint(x: mid + 68, y: 8), control1: CGPoint(x: mid + 49, y: 24), control2: CGPoint(x: mid + 56, y: 8))
        path.addCurve(to: CGPoint(x: rect.width * 0.83, y: 9), control1: CGPoint(x: mid + 108, y: 7), control2: CGPoint(x: rect.width * 0.72, y: 12))
        path.addCurve(to: CGPoint(x: rect.maxX - 4, y: 3), control1: CGPoint(x: rect.width * 0.905, y: 8), control2: CGPoint(x: rect.width * 0.96, y: 3))
        return path
    }
}

private struct MilliNavigationBridgeLowerHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX

        path.move(to: CGPoint(x: 2, y: 11))
        path.addCurve(to: CGPoint(x: rect.width * 0.17, y: 18), control1: CGPoint(x: rect.width * 0.04, y: 11), control2: CGPoint(x: rect.width * 0.09, y: 17))
        path.addCurve(to: CGPoint(x: mid - 67, y: 17), control1: CGPoint(x: rect.width * 0.27, y: 20), control2: CGPoint(x: mid - 104, y: 17))
        path.addCurve(to: CGPoint(x: mid - 42, y: 36), control1: CGPoint(x: mid - 56, y: 17), control2: CGPoint(x: mid - 50, y: 32))
        path.addCurve(to: CGPoint(x: mid + 42, y: 36), control1: CGPoint(x: mid - 21, y: 49), control2: CGPoint(x: mid + 21, y: 49))
        path.addCurve(to: CGPoint(x: mid + 67, y: 17), control1: CGPoint(x: mid + 50, y: 32), control2: CGPoint(x: mid + 56, y: 17))
        path.addCurve(to: CGPoint(x: rect.width * 0.83, y: 18), control1: CGPoint(x: mid + 104, y: 17), control2: CGPoint(x: rect.width * 0.73, y: 20))
        path.addCurve(to: CGPoint(x: rect.maxX - 2, y: 11), control1: CGPoint(x: rect.width * 0.91, y: 17), control2: CGPoint(x: rect.width * 0.96, y: 11))
        return path
    }
}

private struct MilliNavigationCyanSeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = rect.midX
        p.move(to: CGPoint(x: rect.width * 0.05, y: 18))
        p.addCurve(to: CGPoint(x: mid - 70, y: 20), control1: CGPoint(x: rect.width * 0.18, y: 24), control2: CGPoint(x: mid - 112, y: 18))
        p.addCurve(to: CGPoint(x: mid - 47, y: 35), control1: CGPoint(x: mid - 60, y: 20), control2: CGPoint(x: mid - 54, y: 31))
        p.move(to: CGPoint(x: mid + 47, y: 35))
        p.addCurve(to: CGPoint(x: mid + 70, y: 20), control1: CGPoint(x: mid + 54, y: 31), control2: CGPoint(x: mid + 60, y: 20))
        p.addCurve(to: CGPoint(x: rect.width * 0.95, y: 18), control1: CGPoint(x: mid + 112, y: 18), control2: CGPoint(x: rect.width * 0.82, y: 24))
        return p
    }
}

private struct MilliNavigationLowerEdgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.width * 0.08, y: rect.height - 2))
        p.addCurve(
            to: CGPoint(x: rect.width * 0.92, y: rect.height - 2),
            control1: CGPoint(x: rect.width * 0.34, y: rect.height - 5),
            control2: CGPoint(x: rect.width * 0.66, y: rect.height - 5)
        )
        return p
    }
}
