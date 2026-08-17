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
// Signature sculpted chrome bridge with a mechanically docked center-M command control.
// This is intentionally not a stock TabView or floating pill.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    private let commandSize: CGFloat = 82
    private let shellHeight: CGFloat = MilliSpacing.bottomNavHeight

    var body: some View {
        ZStack(alignment: .top) {
            navigationTray
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
                    colors: [Color(hex: "171D22"), MilliColors.navBarBackground, Color(hex: "040607")],
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
                    colors: [Color.white.opacity(0.035), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 32)
                .mask(MilliNavigationTrayShape())
            }
            .shadow(color: .black.opacity(0.78), radius: 15, x: 0, y: -4)
    }

    private var chromeBridge: some View {
        ZStack {
            MilliNavigationBridgeShape()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: MilliColors.chromeDeep, location: 0.00),
                            .init(color: MilliColors.chromeWhite, location: 0.22),
                            .init(color: MilliColors.chromeMid, location: 0.52),
                            .init(color: MilliColors.chromeDark, location: 0.78),
                            .init(color: MilliColors.chromeDeep, location: 1.00)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliNavigationBridgeShape()
                        .stroke(Color.white.opacity(0.50), lineWidth: 0.55)
                }

            MilliNavigationBridgeHighlightShape()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.85),
                            MilliColors.cyanGlow.opacity(0.34),
                            Color.white.opacity(0.75),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 0.9, lineCap: .round)
                )
                .blur(radius: 0.15)
        }
        .shadow(color: .black.opacity(0.72), radius: 4, y: 3)
        .shadow(color: MilliColors.cyanGlow.opacity(0.10), radius: 5, y: -1)
    }

    private var sideDestinations: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.payouts)
            Spacer().frame(width: commandSize + 30)
            tabButton(.mileage)
            tabButton(.more)
        }
        .padding(.horizontal, 8)
        .padding(.top, 27)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 2.5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16.5, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isSelected ? MilliColors.navTabActive : MilliColors.navTabInactive)
                    .shadow(
                        color: isSelected ? MilliColors.cyanGlow.opacity(0.48) : .clear,
                        radius: 4
                    )

                Text(tab.rawValue)
                    .font(.custom("Inter-Medium", size: 9.3, relativeTo: .caption2))
                    .tracking(0.15)
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : MilliColors.navTabInactive.opacity(0.80))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Capsule(style: .continuous)
                    .fill(isSelected ? MilliColors.cyanGlow : Color.clear)
                    .frame(width: 11, height: 1.5)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.52) : .clear, radius: 3)
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
                    .fill(Color.black.opacity(0.82))
                    .frame(width: commandSize + 18, height: commandSize + 18)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.92), radius: 12, y: 6)

                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                MilliColors.chromeDeep,
                                MilliColors.chromeWhite,
                                MilliColors.chromeMid,
                                MilliColors.chromeWhite,
                                MilliColors.chromeDark,
                                MilliColors.chromeWhite,
                                MilliColors.chromeDeep
                            ],
                            center: .center
                        )
                    )
                    .frame(width: commandSize, height: commandSize)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.42), lineWidth: 0.65)
                    }

                Circle()
                    .fill(Color(hex: "05080A"))
                    .frame(width: commandSize - 9, height: commandSize - 9)
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.95), lineWidth: 2)
                    }

                segmentedLightRing

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "153A4A"), Color(hex: "081218"), Color.black],
                            center: .center,
                            startRadius: 1,
                            endRadius: 33
                        )
                    )
                    .frame(width: commandSize - 29, height: commandSize - 29)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.16), lineWidth: 0.7)
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.16), radius: 8)

                // The approved M asset contains a black source field. Screen compositing
                // removes that plate against the black-glass face while preserving the M.
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 43, height: 43)
                    .blendMode(.screen)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.38), radius: 4)
                    .accessibilityHidden(true)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.13), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: commandSize - 34, height: commandSize - 34)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse().frame(height: 17)
                            Spacer()
                        }
                    )
                    .allowsHitTesting(false)
            }
            .frame(width: commandSize + 20, height: commandSize + 20)
        }
        .buttonStyle(MilliCommandButtonStyle())
        .offset(y: -19)
        .accessibilityLabel("Milli home command")
        .accessibilityHint("Returns to the Milli home dashboard")
    }

    private var segmentedLightRing: some View {
        ZStack {
            Circle()
                .stroke(MilliColors.cyanGlow.opacity(0.44), lineWidth: 2)
                .frame(width: commandSize - 18, height: commandSize - 18)
                .shadow(color: MilliColors.cyanGlow.opacity(0.56), radius: 5)

            ForEach(0..<40, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index % 4 == 0 ? MilliColors.chromeLight : MilliColors.cyanGlow)
                    .frame(width: 1.1, height: index % 4 == 0 ? 5.8 : 4.1)
                    .offset(y: -(commandSize - 22) / 2)
                    .rotationEffect(.degrees(Double(index) * 9))
                    .opacity(index % 4 == 0 ? 0.90 : 0.68)
            }
        }
    }
}

private struct MilliCommandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.055 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Sculpted shell geometry

private struct MilliNavigationTrayShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX
        let top: CGFloat = 16

        path.move(to: CGPoint(x: 0, y: top))
        path.addCurve(
            to: CGPoint(x: mid - 60, y: top),
            control1: CGPoint(x: rect.width * 0.18, y: top - 2),
            control2: CGPoint(x: mid - 96, y: top - 2)
        )
        path.addCurve(
            to: CGPoint(x: mid - 36, y: 34),
            control1: CGPoint(x: mid - 50, y: top),
            control2: CGPoint(x: mid - 45, y: 29)
        )
        path.addCurve(
            to: CGPoint(x: mid + 36, y: 34),
            control1: CGPoint(x: mid - 18, y: 46),
            control2: CGPoint(x: mid + 18, y: 46)
        )
        path.addCurve(
            to: CGPoint(x: mid + 60, y: top),
            control1: CGPoint(x: mid + 45, y: 29),
            control2: CGPoint(x: mid + 50, y: top)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: top),
            control1: CGPoint(x: mid + 96, y: top - 2),
            control2: CGPoint(x: rect.width * 0.82, y: top - 2)
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
        let upper: CGFloat = 9
        let lower: CGFloat = 19

        path.move(to: CGPoint(x: 0, y: upper))
        path.addCurve(
            to: CGPoint(x: mid - 61, y: upper),
            control1: CGPoint(x: rect.width * 0.22, y: upper - 1),
            control2: CGPoint(x: mid - 96, y: upper - 1)
        )
        path.addCurve(
            to: CGPoint(x: mid - 37, y: 29),
            control1: CGPoint(x: mid - 51, y: upper),
            control2: CGPoint(x: mid - 45, y: 25)
        )
        path.addCurve(
            to: CGPoint(x: mid + 37, y: 29),
            control1: CGPoint(x: mid - 18, y: 40),
            control2: CGPoint(x: mid + 18, y: 40)
        )
        path.addCurve(
            to: CGPoint(x: mid + 61, y: upper),
            control1: CGPoint(x: mid + 45, y: 25),
            control2: CGPoint(x: mid + 51, y: upper)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: upper),
            control1: CGPoint(x: mid + 96, y: upper - 1),
            control2: CGPoint(x: rect.width * 0.78, y: upper - 1)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: lower))
        path.addCurve(
            to: CGPoint(x: mid + 61, y: lower),
            control1: CGPoint(x: rect.width * 0.78, y: lower + 1),
            control2: CGPoint(x: mid + 96, y: lower + 1)
        )
        path.addCurve(
            to: CGPoint(x: mid + 40, y: 37),
            control1: CGPoint(x: mid + 52, y: lower),
            control2: CGPoint(x: mid + 47, y: 33)
        )
        path.addCurve(
            to: CGPoint(x: mid - 40, y: 37),
            control1: CGPoint(x: mid + 19, y: 49),
            control2: CGPoint(x: mid - 19, y: 49)
        )
        path.addCurve(
            to: CGPoint(x: mid - 61, y: lower),
            control1: CGPoint(x: mid - 47, y: 33),
            control2: CGPoint(x: mid - 52, y: lower)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: lower),
            control1: CGPoint(x: mid - 96, y: lower + 1),
            control2: CGPoint(x: rect.width * 0.22, y: lower + 1)
        )
        path.closeSubpath()
        return path
    }
}

private struct MilliNavigationBridgeHighlightShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX
        let y: CGFloat = 10

        path.move(to: CGPoint(x: 5, y: y))
        path.addCurve(
            to: CGPoint(x: mid - 61, y: y),
            control1: CGPoint(x: rect.width * 0.22, y: y - 1),
            control2: CGPoint(x: mid - 96, y: y - 1)
        )
        path.addCurve(
            to: CGPoint(x: mid - 38, y: 29),
            control1: CGPoint(x: mid - 51, y: y),
            control2: CGPoint(x: mid - 45, y: 25)
        )
        path.addCurve(
            to: CGPoint(x: mid + 38, y: 29),
            control1: CGPoint(x: mid - 18, y: 40),
            control2: CGPoint(x: mid + 18, y: 40)
        )
        path.addCurve(
            to: CGPoint(x: mid + 61, y: y),
            control1: CGPoint(x: mid + 45, y: 25),
            control2: CGPoint(x: mid + 51, y: y)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - 5, y: y),
            control1: CGPoint(x: mid + 96, y: y - 1),
            control2: CGPoint(x: rect.width * 0.78, y: y - 1)
        )
        return path
    }
}
