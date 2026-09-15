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
        case .activity: return "location.north.fill"
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
// Canonical navigation hardware. The chassis is intentionally darker and more
// machined than decorative: polished gunmetal, recessed black-glass controls,
// restrained cyan optics and one dominant center M instrument.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let barHeight: CGFloat = MilliSpacing.bottomNavHeight
    private let centerDiameter: CGFloat = 78
    private let centerGap: CGFloat = 88

    var body: some View {
        ZStack(alignment: .top) {
            outerChassis
            innerGlass
            topMetalBridge
            tabRow
            centerDial
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .padding(.horizontal, 6)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.black)
                .frame(height: 34)
                .offset(y: 34)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Milli navigation")
    }

    private var outerChassis: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "E7EAEC"), location: 0.00),
                        .init(color: Color(hex: "90979D"), location: 0.075),
                        .init(color: Color(hex: "464C51"), location: 0.18),
                        .init(color: Color(hex: "20252A"), location: 0.42),
                        .init(color: Color(hex: "5F666B"), location: 0.68),
                        .init(color: Color(hex: "171B1F"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.78), Color(hex: "737A80").opacity(0.82), Color.black.opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.72
                    )
            }
            .shadow(color: .black.opacity(0.90), radius: 16, y: 9)
            .shadow(color: MilliColors.cyanGlow.opacity(0.028), radius: 11, y: -2)
    }

    private var innerGlass: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "12171B"), location: 0.00),
                        .init(color: Color(hex: "070A0D"), location: 0.36),
                        .init(color: Color(hex: "010203"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), MilliColors.cyanGlow.opacity(0.10), Color.white.opacity(0.015)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.62
                    )
            }
            .scaleEffect(x: 0.986, y: 0.89, anchor: .bottom)
            .offset(y: 3)
            .allowsHitTesting(false)
    }

    private var topMetalBridge: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.18),
                Color.white.opacity(0.72),
                Color(hex: "AAB1B6").opacity(0.62),
                Color.white.opacity(0.10),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(maxWidth: .infinity)
        .frame(height: 1.15)
        .padding(.horizontal, 20)
        .offset(y: 14)
        .allowsHitTesting(false)
    }

    private var tabRow: some View {
        HStack(spacing: 0) {
            tabButton(.vault)
            tabButton(.activity)

            Spacer()
                .frame(width: centerGap)

            tabButton(.wealth)
            tabButton(.cockpit)
        }
        .padding(.horizontal, 8)
        .padding(.top, 20)
        .frame(height: barHeight, alignment: .top)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "20272C"),
                                    Color(hex: "090C0F"),
                                    Color.black
                                ],
                                center: UnitPoint(x: 0.38, y: 0.28),
                                startRadius: 1,
                                endRadius: 19
                            )
                        )
                        .frame(width: 30, height: 30)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.34), Color(hex: "5E666C"), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.65
                                )
                        }
                        .shadow(color: .black.opacity(0.72), radius: 4, y: 2)
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.22) : .clear, radius: 4)

                    Image(systemName: tab.icon)
                        .font(.system(size: tab == .cockpit ? 14 : 13.5, weight: .semibold))
                        .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "C2C6CA"))
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.34) : .clear, radius: 3)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-Medium", size: 9.2, relativeTo: .caption))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "9EA5AB"))
                    .lineLimit(1)

                Capsule()
                    .fill(isSelected ? MilliColors.cyanGlow : Color.clear)
                    .frame(width: 18, height: 1.4)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.42) : .clear, radius: 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var centerDial: some View {
        Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "EEF1F2"),
                                Color(hex: "535A60"),
                                Color(hex: "BEC4C8"),
                                Color(hex: "22282D"),
                                Color(hex: "E3E6E8"),
                                Color(hex: "656C72"),
                                Color(hex: "D3D7DA")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: centerDiameter, height: centerDiameter)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.66), lineWidth: 0.70)
                    }
                    .shadow(color: .black.opacity(0.92), radius: 10, y: 6)

                Circle()
                    .fill(Color(hex: "030506"))
                    .frame(width: centerDiameter - 9, height: centerDiameter - 9)
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.95), lineWidth: 1.1)
                    }

                SegmentedArcRing(segments: 34, gapDegrees: 4.8)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "9AFBFF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2.8, lineCap: .butt)
                    )
                    .frame(width: centerDiameter - 17, height: centerDiameter - 17)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.48), radius: 4)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "182127"), Color(hex: "06090B"), .black],
                            center: UnitPoint(x: 0.38, y: 0.26),
                            startRadius: 1,
                            endRadius: 31
                        )
                    )
                    .frame(width: centerDiameter - 29, height: centerDiameter - 29)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.52), Color(hex: "656C72"), Color.white.opacity(0.055)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.75
                            )
                    }

                MilliMMark(size: 36)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.34), radius: 4)
            }
            .scaleEffect(isDialPressed ? 0.965 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isDialPressed)
        }
        .buttonStyle(.plain)
        .offset(y: -1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isDialPressed = true }
                .onEnded { _ in isDialPressed = false }
        )
        .accessibilityLabel("Home")
        .accessibilityHint("Returns to the Milli dashboard")
    }
}

// MARK: - Chassis silhouette

struct CanonicalNavShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let center = rect.midX
        let corner: CGFloat = 21
        let shoulder: CGFloat = 58
        let crestDepth: CGFloat = 14

        path.move(to: CGPoint(x: corner, y: crestDepth))
        path.addLine(to: CGPoint(x: center - shoulder, y: crestDepth))
        path.addCurve(
            to: CGPoint(x: center - 39, y: 4),
            control1: CGPoint(x: center - 52, y: crestDepth),
            control2: CGPoint(x: center - 47, y: 7)
        )
        path.addCurve(
            to: CGPoint(x: center, y: 0),
            control1: CGPoint(x: center - 26, y: 0),
            control2: CGPoint(x: center - 13, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: center + 39, y: 4),
            control1: CGPoint(x: center + 13, y: 0),
            control2: CGPoint(x: center + 26, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: center + shoulder, y: crestDepth),
            control1: CGPoint(x: center + 47, y: 7),
            control2: CGPoint(x: center + 52, y: crestDepth)
        )
        path.addLine(to: CGPoint(x: width - corner, y: crestDepth))
        path.addQuadCurve(to: CGPoint(x: width, y: crestDepth + corner), control: CGPoint(x: width, y: crestDepth))
        path.addLine(to: CGPoint(x: width, y: height - corner))
        path.addQuadCurve(to: CGPoint(x: width - corner, y: height), control: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: corner, y: height))
        path.addQuadCurve(to: CGPoint(x: 0, y: height - corner), control: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: crestDepth + corner))
        path.addQuadCurve(to: CGPoint(x: corner, y: crestDepth), control: CGPoint(x: 0, y: crestDepth))
        path.closeSubpath()
        return path
    }
}

struct ChassisShape: Shape {
    var crestHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        CanonicalNavShape().path(in: rect)
    }
}

// MARK: - Segmented ring

struct SegmentedArcRing: Shape {
    var segments: Int
    var gapDegrees: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let count = max(1, segments)
        let segmentAngle = 360.0 / CGFloat(count)
        let arcAngle = max(1, segmentAngle - gapDegrees)

        for index in 0..<count {
            let start = Angle.degrees(Double(index) * Double(segmentAngle) - 90 - Double(gapDegrees) / 2)
            let end = start + .degrees(Double(arcAngle))
            path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        }

        return path
    }
}
