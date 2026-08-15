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

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onMDialTap: () -> Void = {}

    private let commandSize: CGFloat = 78
    private let shellHeight: CGFloat = MilliSpacing.bottomNavHeight

    var body: some View {
        ZStack(alignment: .top) {
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
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                }
                .shadow(color: .black.opacity(0.75), radius: 14, x: 0, y: -4)

            MilliNavigationBridgeShape()
                .fill(
                    LinearGradient(
                        colors: [
                            MilliColors.chromeDark,
                            MilliColors.chromeWhite,
                            MilliColors.chromeMid,
                            MilliColors.chromeDeep
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    MilliNavigationBridgeShape()
                        .stroke(Color.white.opacity(0.5), lineWidth: 0.55)
                }
                .shadow(color: MilliColors.cyanGlow.opacity(0.10), radius: 4, y: -1)

            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.payouts)
                Spacer().frame(width: commandSize + 24)
                tabButton(.mileage)
                tabButton(.more)
            }
            .padding(.horizontal, 10)
            .padding(.top, 31)

            commandButton
                .offset(y: -16)
        }
        .frame(height: shellHeight)
        .ignoresSafeArea(edges: .bottom)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(selectedTab == tab ? MilliColors.navTabActive : MilliColors.navTabInactive)
                    .shadow(
                        color: selectedTab == tab ? MilliColors.cyanGlow.opacity(0.42) : .clear,
                        radius: 5
                    )

                Text(tab.rawValue)
                    .font(MilliFont.navLabel)
                    .foregroundStyle(selectedTab == tab ? MilliColors.navTabActive : MilliColors.navTabInactive)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
    }

    private var commandButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onMDialTap()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.55))
                    .frame(width: commandSize + 12, height: commandSize + 12)
                    .shadow(color: .black.opacity(0.85), radius: 10, y: 5)

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

                Circle()
                    .fill(Color(hex: "060B0F"))
                    .frame(width: commandSize - 10, height: commandSize - 10)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.9), lineWidth: 2)
                    }

                segmentedLightRing

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "123244"), Color(hex: "071015"), Color.black],
                            center: .center,
                            startRadius: 1,
                            endRadius: 30
                        )
                    )
                    .frame(width: commandSize - 28, height: commandSize - 28)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.7)
                    }

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.45), radius: 5)
            }
            .frame(width: commandSize + 14, height: commandSize + 14)
        }
        .buttonStyle(MilliCommandButtonStyle())
        .accessibilityLabel("Milli home command")
    }

    private var segmentedLightRing: some View {
        ZStack {
            Circle()
                .stroke(MilliColors.cyanGlow.opacity(0.42), lineWidth: 2)
                .frame(width: commandSize - 18, height: commandSize - 18)
                .shadow(color: MilliColors.cyanGlow.opacity(0.52), radius: 5)

            ForEach(0..<36, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index % 3 == 0 ? MilliColors.chromeLight : MilliColors.cyanGlow)
                    .frame(width: 1.2, height: index % 3 == 0 ? 5.5 : 4)
                    .offset(y: -(commandSize - 22) / 2)
                    .rotationEffect(.degrees(Double(index) * 10))
                    .opacity(index % 3 == 0 ? 0.9 : 0.7)
            }
        }
    }
}

private struct MilliCommandButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? 0.06 : 0)
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
            to: CGPoint(x: mid - 56, y: top),
            control1: CGPoint(x: rect.width * 0.18, y: top - 2),
            control2: CGPoint(x: mid - 92, y: top - 2)
        )
        path.addCurve(
            to: CGPoint(x: mid - 34, y: 31),
            control1: CGPoint(x: mid - 47, y: top),
            control2: CGPoint(x: mid - 42, y: 26)
        )
        path.addCurve(
            to: CGPoint(x: mid + 34, y: 31),
            control1: CGPoint(x: mid - 16, y: 42),
            control2: CGPoint(x: mid + 16, y: 42)
        )
        path.addCurve(
            to: CGPoint(x: mid + 56, y: top),
            control1: CGPoint(x: mid + 42, y: 26),
            control2: CGPoint(x: mid + 47, y: top)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: top),
            control1: CGPoint(x: mid + 92, y: top - 2),
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
        let upper: CGFloat = 10
        let lower: CGFloat = 18

        path.move(to: CGPoint(x: 0, y: upper))
        path.addCurve(
            to: CGPoint(x: mid - 58, y: upper),
            control1: CGPoint(x: rect.width * 0.22, y: upper - 1),
            control2: CGPoint(x: mid - 90, y: upper - 1)
        )
        path.addCurve(
            to: CGPoint(x: mid - 35, y: 26),
            control1: CGPoint(x: mid - 48, y: upper),
            control2: CGPoint(x: mid - 43, y: 23)
        )
        path.addCurve(
            to: CGPoint(x: mid + 35, y: 26),
            control1: CGPoint(x: mid - 17, y: 36),
            control2: CGPoint(x: mid + 17, y: 36)
        )
        path.addCurve(
            to: CGPoint(x: mid + 58, y: upper),
            control1: CGPoint(x: mid + 43, y: 23),
            control2: CGPoint(x: mid + 48, y: upper)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: upper),
            control1: CGPoint(x: mid + 90, y: upper - 1),
            control2: CGPoint(x: rect.width * 0.78, y: upper - 1)
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: lower))
        path.addCurve(
            to: CGPoint(x: mid + 58, y: lower),
            control1: CGPoint(x: rect.width * 0.78, y: lower + 1),
            control2: CGPoint(x: mid + 90, y: lower + 1)
        )
        path.addCurve(
            to: CGPoint(x: mid + 38, y: 34),
            control1: CGPoint(x: mid + 49, y: lower),
            control2: CGPoint(x: mid + 46, y: 31)
        )
        path.addCurve(
            to: CGPoint(x: mid - 38, y: 34),
            control1: CGPoint(x: mid + 17, y: 45),
            control2: CGPoint(x: mid - 17, y: 45)
        )
        path.addCurve(
            to: CGPoint(x: mid - 58, y: lower),
            control1: CGPoint(x: mid - 46, y: 31),
            control2: CGPoint(x: mid - 49, y: lower)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: lower),
            control1: CGPoint(x: mid - 90, y: lower + 1),
            control2: CGPoint(x: rect.width * 0.22, y: lower + 1)
        )
        path.closeSubpath()
        return path
    }
}
