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
// Canonical navigation: slim black-glass tray, precision chrome edge and one
// dominant center M assembly. The four destinations are deliberately quiet so
// the control reads like premium financial hardware instead of five toy buttons.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let barHeight: CGFloat = 100
    private let centerDiameter: CGFloat = 86
    private let centerGap: CGFloat = 96

    var body: some View {
        ZStack(alignment: .top) {
            canonicalChassis
            canonicalFace
            tabRow
            centerDial
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .padding(.horizontal, 8)
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

    private var canonicalChassis: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "F7F9FA"), location: 0.00),
                        .init(color: Color(hex: "A0A7AE"), location: 0.18),
                        .init(color: Color(hex: "E5E8EA"), location: 0.36),
                        .init(color: Color(hex: "555D65"), location: 0.70),
                        .init(color: Color(hex: "C5CBD0"), location: 0.90),
                        .init(color: Color(hex: "6A7178"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.82), Color(hex: "777F87"), Color.white.opacity(0.30)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            }
            .shadow(color: .black.opacity(0.82), radius: 16, y: 7)
    }

    private var canonicalFace: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "11171C"), Color(hex: "070A0D"), Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(MilliColors.cyanGlow.opacity(0.12), lineWidth: 0.75)
            }
            .scaleEffect(x: 0.985, y: 0.91, anchor: .bottom)
            .offset(y: 3)
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
        .padding(.top, 29)
        .frame(height: barHeight, alignment: .top)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                            ? AnyShapeStyle(
                                RadialGradient(
                                    colors: [MilliColors.cyanGlow.opacity(0.24), Color.white.opacity(0.05), Color.clear],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 22
                                )
                            )
                            : AnyShapeStyle(Color.clear)
                        )
                        .frame(width: 38, height: 38)

                    Image(systemName: tab.icon)
                        .font(.system(size: tab == .cockpit ? 18 : 17, weight: .semibold))
                        .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "C4C9CE"))
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.38) : .clear, radius: 4)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-Medium", size: 10.5, relativeTo: .caption))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "A8AFB5"))
                    .lineLimit(1)
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
                                Color(hex: "F8FAFB"),
                                Color(hex: "6A7178"),
                                Color(hex: "E2E6E9"),
                                Color(hex: "40474E"),
                                Color(hex: "F3F5F6"),
                                Color(hex: "747B82"),
                                Color(hex: "EBEEF0")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: centerDiameter, height: centerDiameter)
                    .overlay { Circle().stroke(Color.white.opacity(0.62), lineWidth: 0.8) }
                    .shadow(color: .black.opacity(0.85), radius: 9, y: 5)

                Circle()
                    .fill(Color(hex: "070B0E"))
                    .frame(width: centerDiameter - 10, height: centerDiameter - 10)
                    .overlay { Circle().stroke(Color.black.opacity(0.9), lineWidth: 1.5) }

                SegmentedArcRing(segments: 32, gapDegrees: 5.5)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3.3, lineCap: .butt)
                    )
                    .frame(width: centerDiameter - 18, height: centerDiameter - 18)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.45), radius: 5)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "172027"), Color(hex: "080B0E"), Color.black],
                            center: UnitPoint(x: 0.42, y: 0.30),
                            startRadius: 1,
                            endRadius: 34
                        )
                    )
                    .frame(width: centerDiameter - 31, height: centerDiameter - 31)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.50), Color(hex: "717981"), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    }

                MilliMMark(size: 40)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 4)
            }
            .scaleEffect(isDialPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.76), value: isDialPressed)
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
        var p = Path()
        let w = rect.width
        let h = rect.height
        let center = rect.midX
        let corner: CGFloat = 24
        let shoulder: CGFloat = 62
        let crestDepth: CGFloat = 18

        p.move(to: CGPoint(x: corner, y: crestDepth))
        p.addLine(to: CGPoint(x: center - shoulder, y: crestDepth))
        p.addCurve(
            to: CGPoint(x: center - 42, y: 4),
            control1: CGPoint(x: center - 54, y: crestDepth),
            control2: CGPoint(x: center - 50, y: 7)
        )
        p.addCurve(
            to: CGPoint(x: center, y: 0),
            control1: CGPoint(x: center - 28, y: 0),
            control2: CGPoint(x: center - 14, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: center + 42, y: 4),
            control1: CGPoint(x: center + 14, y: 0),
            control2: CGPoint(x: center + 28, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: center + shoulder, y: crestDepth),
            control1: CGPoint(x: center + 50, y: 7),
            control2: CGPoint(x: center + 54, y: crestDepth)
        )
        p.addLine(to: CGPoint(x: w - corner, y: crestDepth))
        p.addQuadCurve(to: CGPoint(x: w, y: crestDepth + corner), control: CGPoint(x: w, y: crestDepth))
        p.addLine(to: CGPoint(x: w, y: h - corner))
        p.addQuadCurve(to: CGPoint(x: w - corner, y: h), control: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: corner, y: h))
        p.addQuadCurve(to: CGPoint(x: 0, y: h - corner), control: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: crestDepth + corner))
        p.addQuadCurve(to: CGPoint(x: corner, y: crestDepth), control: CGPoint(x: 0, y: crestDepth))
        p.closeSubpath()
        return p
    }
}

// Compatibility alias retained for any older previews/components.
struct ChassisShape: Shape {
    var crestHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        CanonicalNavShape().path(in: rect)
    }
}

// MARK: - Segmented arc ring

struct SegmentedArcRing: Shape {
    var segments: Int
    var gapDegrees: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let segmentAngle = 360.0 / CGFloat(max(1, segments))
        let arcAngle = max(1, segmentAngle - gapDegrees)

        for index in 0..<max(1, segments) {
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
