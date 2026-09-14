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
// Canonical navigation hardware. The bar uses a low-profile machined-silver
// bridge over black glass, four quiet tab destinations and one dominant center
// M assembly. It is intentionally cinematic without becoming visually heavy.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let barHeight: CGFloat = MilliSpacing.bottomNavHeight
    private let centerDiameter: CGFloat = 80
    private let centerGap: CGFloat = 92

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
                        .init(color: Color(hex: "F7F9FA"), location: 0.00),
                        .init(color: Color(hex: "9AA1A7"), location: 0.10),
                        .init(color: Color(hex: "E5E8EA"), location: 0.21),
                        .init(color: Color(hex: "646B72"), location: 0.48),
                        .init(color: Color(hex: "BFC4C8"), location: 0.72),
                        .init(color: Color(hex: "41474D"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.92), Color(hex: "737A80"), Color.white.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: .black.opacity(0.84), radius: 15, y: 8)
            .shadow(color: MilliColors.cyanGlow.opacity(0.035), radius: 10, y: -2)
    }

    private var innerGlass: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "151B1F"), location: 0.00),
                        .init(color: Color(hex: "090D10"), location: 0.34),
                        .init(color: Color(hex: "020304"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), MilliColors.cyanGlow.opacity(0.12), Color.white.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.65
                    )
            }
            .scaleEffect(x: 0.986, y: 0.90, anchor: .bottom)
            .offset(y: 3)
            .allowsHitTesting(false)
    }

    private var topMetalBridge: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.70),
                Color(hex: "B5BBC0").opacity(0.65),
                Color.white.opacity(0.18),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(maxWidth: .infinity)
        .frame(height: 1.2)
        .padding(.horizontal, 20)
        .offset(y: 15)
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
        .padding(.top, 24)
        .frame(height: barHeight, alignment: .top)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: tab == .cockpit ? 17 : 16, weight: .semibold))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "BDC2C7"))
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.28) : .clear, radius: 3)
                    .frame(height: 27)

                Text(tab.displayName)
                    .font(.custom("Inter-Medium", size: 9.5, relativeTo: .caption))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "9EA5AB"))
                    .lineLimit(1)

                Capsule()
                    .fill(isSelected ? MilliColors.cyanGlow : Color.clear)
                    .frame(width: 20, height: 1.5)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.40) : .clear, radius: 2)
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
                                Color(hex: "F8F9FA"),
                                Color(hex: "5D646A"),
                                Color(hex: "DCE0E3"),
                                Color(hex: "333A40"),
                                Color(hex: "F2F4F5"),
                                Color(hex: "777E84"),
                                Color(hex: "E7EAEC")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: centerDiameter, height: centerDiameter)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.70), lineWidth: 0.75)
                    }
                    .shadow(color: .black.opacity(0.86), radius: 9, y: 5)

                Circle()
                    .fill(Color(hex: "05080A"))
                    .frame(width: centerDiameter - 9, height: centerDiameter - 9)
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.95), lineWidth: 1.1)
                    }

                SegmentedArcRing(segments: 34, gapDegrees: 4.8)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3.0, lineCap: .butt)
                    )
                    .frame(width: centerDiameter - 17, height: centerDiameter - 17)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.46), radius: 4)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "192229"), Color(hex: "070A0D"), .black],
                            center: UnitPoint(x: 0.40, y: 0.28),
                            startRadius: 1,
                            endRadius: 31
                        )
                    )
                    .frame(width: centerDiameter - 29, height: centerDiameter - 29)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.50), Color(hex: "747B82"), Color.white.opacity(0.07)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }

                MilliMMark(size: 37)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 4)
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
        let crestDepth: CGFloat = 15

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

// Compatibility facade retained for screens/tests that referenced the earlier
// chassis type directly.
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

#Preview {
    ZStack(alignment: .bottom) {
        MilliColors.obsidian.ignoresSafeArea()
        MilliNavBar(selectedTab: .constant(.vault))
    }
}
