import SwiftUI
import UIKit

// MARK: - MilliTab

enum MilliTab: String, CaseIterable {
    case home = "Home"
    case payouts = "Payouts"
    case mDial = "M"
    case mileage = "Mileage"
    case more = "More"

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .payouts: return "doc.text.fill"
        case .mDial: return ""
        case .mileage: return "car.fill"
        case .more: return "ellipsis"
        }
    }
}

// MARK: - MilliNavBar
// Production signature navigation: recessed graphite tray + sculpted chrome bridge
// + multi-layered center-M mechanical command assembly. Never replace with TabView.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

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
    }

    private var navigationTray: some View {
        MilliNavigationTrayShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "10161B"), location: 0.00),
                        .init(color: Color(hex: "090D10"), location: 0.40),
                        .init(color: Color(hex: "030506"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                MilliNavigationTrayShape()
                    .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.04), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 34)
                .mask(MilliNavigationTrayShape())
            }
            .shadow(color: .black.opacity(0.92), radius: 18, x: 0, y: -5)
    }

    private var underBridgeShadow: some View {
        MilliNavigationBridgeShape()
            .stroke(Color.black.opacity(0.82), lineWidth: 5)
            .blur(radius: 4)
            .offset(y: 4)
    }

    private var chromeBridge: some View {
        ZStack {
            MilliNavigationBridgeShape()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "2B3136"), location: 0.00),
                            .init(color: MilliColors.chromeWhite, location: 0.16),
                            .init(color: Color(hex: "8F989F"), location: 0.36),
                            .init(color: MilliColors.chromeWhite, location: 0.52),
                            .init(color: Color(hex: "727B82"), location: 0.70),
                            .init(color: MilliColors.chromeDeep, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliNavigationBridgeShape()
                        .stroke(Color.white.opacity(0.58), lineWidth: 0.65)
                }

            MilliNavigationBridgeHighlightShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.96),
                            MilliColors.cyanGlow.opacity(0.30),
                            Color.white.opacity(0.90),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 1.05, lineCap: .round)
                )

            MilliNavigationBridgeHighlightShape()
                .stroke(MilliColors.cyanGlow.opacity(0.10), lineWidth: 2.2)
                .blur(radius: 2.5)
        }
        .shadow(color: .black.opacity(0.80), radius: 4, y: 3)
        .shadow(color: MilliColors.cyanGlow.opacity(0.08), radius: 7, y: -1)
    }

    private var sideDestinations: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.payouts)
            Spacer().frame(width: commandSize + 34)
            tabButton(.mileage)
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
                    .minimumScaleFactor(0.82)

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
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onMDialTap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.90))
                    .frame(width: commandSize + 24, height: commandSize + 24)
                    .overlay { Circle().stroke(Color.white.opacity(0.055), lineWidth: 1) }
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
                    .overlay { Circle().stroke(Color.white.opacity(0.62), lineWidth: 0.75) }
                    .shadow(color: Color.white.opacity(0.10), radius: 2, y: -1)

                Circle()
                    .fill(Color(hex: "020405"))
                    .frame(width: commandSize - 4, height: commandSize - 4)
                    .overlay { Circle().stroke(Color.black.opacity(0.98), lineWidth: 2.5) }

                segmentedLightRing

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
                    .shadow(color: MilliColors.cyanGlow.opacity(0.24), radius: 9)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
                    .blendMode(.screen)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.42), radius: 5)
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
        .accessibilityLabel("Milli home command")
        .accessibilityHint("Returns to the Milli home dashboard")
    }

    private var segmentedLightRing: some View {
        ZStack {
            Circle()
                .stroke(MilliColors.cyanGlow.opacity(0.50), lineWidth: 2.2)
                .frame(width: commandSize - 14, height: commandSize - 14)
                .shadow(color: MilliColors.cyanGlow.opacity(0.70), radius: 6)

            Circle()
                .stroke(Color.black.opacity(0.95), lineWidth: 1.1)
                .frame(width: commandSize - 21, height: commandSize - 21)

            ForEach(0..<44, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index % 4 == 0 ? MilliColors.chromeLight : MilliColors.cyanGlow)
                    .frame(width: 1.15, height: index % 4 == 0 ? 6.2 : 4.5)
                    .offset(y: -(commandSize - 18) / 2)
                    .rotationEffect(.degrees(Double(index) * (360.0 / 44.0)))
                    .opacity(index % 4 == 0 ? 0.96 : 0.74)
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

// MARK: - Sculpted shell geometry

private struct MilliNavigationTrayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX
        let top: CGFloat = 15

        path.move(to: CGPoint(x: 0, y: top))
        path.addCurve(to: CGPoint(x: mid - 66, y: top), control1: CGPoint(x: rect.width * 0.18, y: top - 2), control2: CGPoint(x: mid - 102, y: top - 2))
        path.addCurve(to: CGPoint(x: mid - 40, y: 36), control1: CGPoint(x: mid - 55, y: top), control2: CGPoint(x: mid - 49, y: 30))
        path.addCurve(to: CGPoint(x: mid + 40, y: 36), control1: CGPoint(x: mid - 20, y: 50), control2: CGPoint(x: mid + 20, y: 50))
        path.addCurve(to: CGPoint(x: mid + 66, y: top), control1: CGPoint(x: mid + 49, y: 30), control2: CGPoint(x: mid + 55, y: top))
        path.addCurve(to: CGPoint(x: rect.maxX, y: top), control1: CGPoint(x: mid + 102, y: top - 2), control2: CGPoint(x: rect.width * 0.82, y: top - 2))
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
        let upper: CGFloat = 7
        let lower: CGFloat = 20

        path.move(to: CGPoint(x: 0, y: upper))
        path.addCurve(to: CGPoint(x: mid - 66, y: upper), control1: CGPoint(x: rect.width * 0.22, y: upper - 1), control2: CGPoint(x: mid - 104, y: upper - 1))
        path.addCurve(to: CGPoint(x: mid - 40, y: 31), control1: CGPoint(x: mid - 55, y: upper), control2: CGPoint(x: mid - 49, y: 26))
        path.addCurve(to: CGPoint(x: mid + 40, y: 31), control1: CGPoint(x: mid - 20, y: 44), control2: CGPoint(x: mid + 20, y: 44))
        path.addCurve(to: CGPoint(x: mid + 66, y: upper), control1: CGPoint(x: mid + 49, y: 26), control2: CGPoint(x: mid + 55, y: upper))
        path.addCurve(to: CGPoint(x: rect.maxX, y: upper), control1: CGPoint(x: mid + 104, y: upper - 1), control2: CGPoint(x: rect.width * 0.78, y: upper - 1))

        path.addLine(to: CGPoint(x: rect.maxX, y: lower))
        path.addCurve(to: CGPoint(x: mid + 66, y: lower), control1: CGPoint(x: rect.width * 0.78, y: lower + 1), control2: CGPoint(x: mid + 104, y: lower + 1))
        path.addCurve(to: CGPoint(x: mid + 43, y: 39), control1: CGPoint(x: mid + 56, y: lower), control2: CGPoint(x: mid + 50, y: 35))
        path.addCurve(to: CGPoint(x: mid - 43, y: 39), control1: CGPoint(x: mid + 21, y: 53), control2: CGPoint(x: mid - 21, y: 53))
        path.addCurve(to: CGPoint(x: mid - 66, y: lower), control1: CGPoint(x: mid - 50, y: 35), control2: CGPoint(x: mid - 56, y: lower))
        path.addCurve(to: CGPoint(x: 0, y: lower), control1: CGPoint(x: mid - 104, y: lower + 1), control2: CGPoint(x: rect.width * 0.22, y: lower + 1))
        path.closeSubpath()
        return path
    }
}

private struct MilliNavigationBridgeHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX
        let y: CGFloat = 8

        path.move(to: CGPoint(x: 5, y: y))
        path.addCurve(to: CGPoint(x: mid - 66, y: y), control1: CGPoint(x: rect.width * 0.22, y: y - 1), control2: CGPoint(x: mid - 104, y: y - 1))
        path.addCurve(to: CGPoint(x: mid - 40, y: 31), control1: CGPoint(x: mid - 55, y: y), control2: CGPoint(x: mid - 49, y: 26))
        path.addCurve(to: CGPoint(x: mid + 40, y: 31), control1: CGPoint(x: mid - 20, y: 44), control2: CGPoint(x: mid + 20, y: 44))
        path.addCurve(to: CGPoint(x: mid + 66, y: y), control1: CGPoint(x: mid + 49, y: 26), control2: CGPoint(x: mid + 55, y: y))
        path.addCurve(to: CGPoint(x: rect.maxX - 5, y: y), control1: CGPoint(x: mid + 104, y: y - 1), control2: CGPoint(x: rect.width * 0.78, y: y - 1))
        return path
    }
}
