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
        case .payouts: return "tray.full.fill"
        case .mileage: return "location.north.fill"
        case .wealth: return "chart.bar.fill"
        case .more: return "ellipsis"
        case .mDial: return ""
        }
    }
}

// MARK: - MilliNavBar
// Live navigation implementation based on the approved front-view cockpit reference:
// polished chrome bridge, recessed black-glass tray, cyan instrumentation and the
// canonical Milli M as the HOME control.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    @State private var mDriftX: CGFloat = 0
    @State private var mDriftY: CGFloat = 0
    @State private var mDriftRotation: Double = 0
    @State private var homePulse = false

    private let commandSize: CGFloat = 90
    private let shellHeight: CGFloat = MilliSpacing.bottomNavHeight

    var body: some View {
        ZStack(alignment: .top) {
            recessedTray
            lowerChromeEdge
            lowerCyanEdge
            chromeBridge
            sideDestinations
            commandDock
        }
        .frame(height: shellHeight)
        .ignoresSafeArea(edges: .bottom)
        .accessibilityElement(children: .contain)
        .task { await animateCenterMarkOccasionally() }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                homePulse = true
            }
        }
    }

    // MARK: - Recessed tray

    private var recessedTray: some View {
        RoundedRectangle(cornerRadius: 29, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "151B20"), location: 0.00),
                        .init(color: Color(hex: "090D10"), location: 0.40),
                        .init(color: Color(hex: "020405"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.035), Color.black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 29, style: .continuous)
                    .stroke(Color.white.opacity(0.055), lineWidth: 0.7)
                    .blur(radius: 0.5)
            }
            .padding(.horizontal, 2)
            .padding(.top, 10)
            .shadow(color: .black.opacity(0.95), radius: 20, x: 0, y: -6)
    }

    private var lowerChromeEdge: some View {
        RoundedRectangle(cornerRadius: 29, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(hex: "6F787E").opacity(0.65),
                        Color(hex: "F7FAFC").opacity(0.75),
                        Color(hex: "6F787E").opacity(0.65),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1.35
            )
            .padding(.horizontal, 3)
            .padding(.top, 11)
            .offset(y: -0.4)
            .mask(
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().frame(height: 18)
                }
            )
    }

    private var lowerCyanEdge: some View {
        RoundedRectangle(cornerRadius: 29, style: .continuous)
            .stroke(MilliColors.cyanGlow.opacity(0.26), lineWidth: 0.75)
            .padding(.horizontal, 4)
            .padding(.top, 12)
            .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 3)
            .mask(
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().frame(height: 11)
                }
            )
    }

    // MARK: - Chrome bridge

    private var chromeBridge: some View {
        ZStack {
            CockpitBridgeShape(commandRadius: commandSize * 0.53)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "151A1E"), location: 0.00),
                            .init(color: Color(hex: "FFFFFF"), location: 0.09),
                            .init(color: Color(hex: "BFC6CB"), location: 0.20),
                            .init(color: Color(hex: "626A70"), location: 0.38),
                            .init(color: Color(hex: "E7EBEE"), location: 0.60),
                            .init(color: Color(hex: "737C82"), location: 0.78),
                            .init(color: Color(hex: "1A2024"), location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            CockpitBridgeShape(commandRadius: commandSize * 0.53)
                .stroke(
                    LinearGradient(
                        colors: [
                            MilliColors.cyanGlow.opacity(0.18),
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.72),
                            Color.white.opacity(0.95),
                            MilliColors.cyanGlow.opacity(0.18)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 0.9
                )

            CockpitBridgeHighlightShape(commandRadius: commandSize * 0.53)
                .stroke(Color.white.opacity(0.65), lineWidth: 0.75)

            CockpitBridgeLowerEdgeShape(commandRadius: commandSize * 0.53)
                .stroke(Color.black.opacity(0.75), lineWidth: 0.9)
                .shadow(color: MilliColors.cyanGlow.opacity(0.16), radius: 2, y: 1)
        }
        .frame(height: 47)
        .padding(.horizontal, 5)
        .padding(.top, 8)
        .shadow(color: .black.opacity(0.85), radius: 5, y: 4)
        .shadow(color: MilliColors.cyanGlow.opacity(0.08), radius: 8, y: -1)
    }

    // MARK: - Tabs

    private var sideDestinations: some View {
        HStack(spacing: 0) {
            tabButton(.payouts)
            tabButton(.mileage)
            Spacer().frame(width: commandSize + 30)
            tabButton(.wealth)
            tabButton(.more)
        }
        .padding(.horizontal, 11)
        .padding(.top, 40)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                    ? [MilliColors.cyanGlow, MilliColors.deepCyan]
                                    : [Color(hex: "D0D5D8"), Color(hex: "7B8389")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 27, height: 27)
                        .overlay {
                            Circle().stroke(Color.white.opacity(isSelected ? 0.48 : 0.25), lineWidth: 0.7)
                        }
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.58) : .black.opacity(0.55), radius: isSelected ? 6 : 2, y: 1)

                    Image(systemName: tab.icon)
                        .font(.system(size: 13.5, weight: .bold))
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(isSelected ? MilliColors.blackGlass : Color(hex: "151A1D"))
                }

                Text(tab.rawValue)
                    .font(.custom("Inter-Medium", size: 9.0, relativeTo: .caption2))
                    .tracking(0.05)
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "A8AEB2"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Capsule(style: .continuous)
                    .fill(isSelected ? MilliColors.cyanGlow : Color.clear)
                    .frame(width: 13, height: 1.5)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.75) : .clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Center HOME assembly

    private var commandDock: some View {
        let isHome = selectedTab == .home || selectedTab == .mDial

        return Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onMDialTap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.98))
                    .frame(width: commandSize + 26, height: commandSize + 26)
                    .shadow(color: .black.opacity(0.98), radius: 14, y: 8)

                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "11171B"),
                                Color(hex: "FBFCFD"),
                                Color(hex: "7B858C"),
                                Color(hex: "E9EDF0"),
                                Color(hex: "343C42"),
                                Color(hex: "F7FAFB"),
                                Color(hex: "687178"),
                                Color(hex: "11171B")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: commandSize + 12, height: commandSize + 12)
                    .overlay { Circle().stroke(Color.white.opacity(0.72), lineWidth: 0.9) }

                Circle()
                    .fill(Color(hex: "020405"))
                    .frame(width: commandSize - 2, height: commandSize - 2)
                    .overlay { Circle().stroke(Color.black.opacity(0.95), lineWidth: 2) }

                segmentedLightRing(isHome: isHome)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "0A1B22"), Color(hex: "03080B"), Color.black],
                            center: UnitPoint(x: 0.45, y: 0.38),
                            startRadius: 1,
                            endRadius: 40
                        )
                    )
                    .frame(width: commandSize - 25, height: commandSize - 25)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.65)
                    }

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 53, height: 53)
                    .blendMode(.screen)
                    .offset(x: mDriftX, y: mDriftY)
                    .rotationEffect(.degrees(mDriftRotation))
                    .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.55 : 0.34), radius: 6)
                    .accessibilityHidden(true)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.18), Color.white.opacity(0.02), Color.clear],
                            startPoint: .top,
                            endPoint: UnitPoint(x: 0.5, y: 0.58)
                        )
                    )
                    .frame(width: commandSize - 25, height: commandSize - 25)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse().frame(height: 25)
                            Spacer()
                        }
                    )
                    .allowsHitTesting(false)
            }
            .frame(width: commandSize + 28, height: commandSize + 28)
        }
        .buttonStyle(MilliCommandButtonStyle())
        .offset(y: -14)
        .accessibilityLabel("Home")
        .accessibilityHint("Returns to the Milli home dashboard")
        .accessibilityAddTraits(isHome ? .isSelected : [])
    }

    private func segmentedLightRing(isHome: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(
                    MilliColors.cyanGlow.opacity(isHome ? (homePulse ? 0.88 : 0.66) : 0.48),
                    lineWidth: isHome ? 2.0 : 1.6
                )
                .frame(width: commandSize - 12, height: commandSize - 12)
                .shadow(color: MilliColors.cyanGlow.opacity(isHome ? 0.82 : 0.48), radius: isHome ? 8 : 5)

            ForEach(0..<36, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index % 6 == 0 ? Color.white.opacity(0.94) : MilliColors.cyanGlow)
                    .frame(width: 1.2, height: index % 6 == 0 ? 6.2 : 4.8)
                    .offset(y: -(commandSize - 18) / 2)
                    .rotationEffect(.degrees(Double(index) * 10.0))
                    .opacity(index % 6 == 0 ? 0.95 : (isHome ? 0.92 : 0.68))
            }
        }
    }

    private func animateCenterMarkOccasionally() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 4.4...7.4)))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.spring(response: 0.92, dampingFraction: 0.76)) {
                    mDriftX = CGFloat.random(in: -2.2...2.2)
                    mDriftY = CGFloat.random(in: -1.6...1.6)
                    mDriftRotation = Double.random(in: -1.25...1.25)
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
            .brightness(configuration.isPressed ? 0.055 : 0)
            .animation(.easeOut(duration: 0.11), value: configuration.isPressed)
    }
}

// MARK: - Approved cockpit bridge geometry

private struct CockpitBridgeShape: Shape {
    let commandRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = rect.midX
        let top: CGFloat = 3
        let lower: CGFloat = 19
        let shoulder = commandRadius + 20

        p.move(to: CGPoint(x: 0, y: top))
        p.addLine(to: CGPoint(x: mid - shoulder - 36, y: top))
        p.addCurve(
            to: CGPoint(x: mid - shoulder, y: 8),
            control1: CGPoint(x: mid - shoulder - 18, y: top),
            control2: CGPoint(x: mid - shoulder - 9, y: 5)
        )
        p.addCurve(
            to: CGPoint(x: mid - commandRadius, y: lower),
            control1: CGPoint(x: mid - shoulder + 9, y: 10),
            control2: CGPoint(x: mid - commandRadius - 15, y: lower)
        )
        p.addCurve(
            to: CGPoint(x: mid + commandRadius, y: lower),
            control1: CGPoint(x: mid - commandRadius + 18, y: 42),
            control2: CGPoint(x: mid + commandRadius - 18, y: 42)
        )
        p.addCurve(
            to: CGPoint(x: mid + shoulder, y: 8),
            control1: CGPoint(x: mid + commandRadius + 15, y: lower),
            control2: CGPoint(x: mid + shoulder - 9, y: 10)
        )
        p.addCurve(
            to: CGPoint(x: mid + shoulder + 36, y: top),
            control1: CGPoint(x: mid + shoulder + 9, y: 5),
            control2: CGPoint(x: mid + shoulder + 18, y: top)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: top))
        p.addLine(to: CGPoint(x: rect.maxX, y: 14))
        p.addLine(to: CGPoint(x: mid + shoulder + 28, y: 14))
        p.addCurve(to: CGPoint(x: mid + commandRadius + 2, y: 26), control1: CGPoint(x: mid + shoulder + 12, y: 14), control2: CGPoint(x: mid + commandRadius + 14, y: 22))
        p.addCurve(to: CGPoint(x: mid - commandRadius - 2, y: 26), control1: CGPoint(x: mid + commandRadius - 15, y: 48), control2: CGPoint(x: mid - commandRadius + 15, y: 48))
        p.addCurve(to: CGPoint(x: mid - shoulder - 28, y: 14), control1: CGPoint(x: mid - commandRadius - 14, y: 22), control2: CGPoint(x: mid - shoulder - 12, y: 14))
        p.addLine(to: CGPoint(x: 0, y: 14))
        p.closeSubpath()
        return p
    }
}

private struct CockpitBridgeHighlightShape: Shape {
    let commandRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = rect.midX
        let shoulder = commandRadius + 20

        p.move(to: CGPoint(x: 4, y: 4))
        p.addLine(to: CGPoint(x: mid - shoulder - 34, y: 4))
        p.addCurve(to: CGPoint(x: mid - shoulder, y: 8), control1: CGPoint(x: mid - shoulder - 16, y: 4), control2: CGPoint(x: mid - shoulder - 8, y: 6))
        p.addCurve(to: CGPoint(x: mid - commandRadius, y: 18), control1: CGPoint(x: mid - shoulder + 8, y: 10), control2: CGPoint(x: mid - commandRadius - 14, y: 18))
        p.move(to: CGPoint(x: mid + commandRadius, y: 18))
        p.addCurve(to: CGPoint(x: mid + shoulder, y: 8), control1: CGPoint(x: mid + commandRadius + 14, y: 18), control2: CGPoint(x: mid + shoulder - 8, y: 10))
        p.addCurve(to: CGPoint(x: mid + shoulder + 34, y: 4), control1: CGPoint(x: mid + shoulder + 8, y: 6), control2: CGPoint(x: mid + shoulder + 16, y: 4))
        p.addLine(to: CGPoint(x: rect.maxX - 4, y: 4))
        return p
    }
}

private struct CockpitBridgeLowerEdgeShape: Shape {
    let commandRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let mid = rect.midX
        let shoulder = commandRadius + 20

        p.move(to: CGPoint(x: 4, y: 14))
        p.addLine(to: CGPoint(x: mid - shoulder - 28, y: 14))
        p.addCurve(to: CGPoint(x: mid - commandRadius - 2, y: 25), control1: CGPoint(x: mid - shoulder - 12, y: 14), control2: CGPoint(x: mid - commandRadius - 14, y: 21))
        p.move(to: CGPoint(x: mid + commandRadius + 2, y: 25))
        p.addCurve(to: CGPoint(x: mid + shoulder + 28, y: 14), control1: CGPoint(x: mid + commandRadius + 14, y: 21), control2: CGPoint(x: mid + shoulder + 12, y: 14))
        p.addLine(to: CGPoint(x: rect.maxX - 4, y: 14))
        return p
    }
}