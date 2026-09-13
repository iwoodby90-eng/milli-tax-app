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
// Approved canonical navigation: low-profile black glass, a restrained polished
// metal bridge, and one dominant center-M assembly. The chrome frames the UI;
// it does not become the UI.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let barHeight: CGFloat = MilliSpacing.bottomNavHeight
    private let centerDiameter: CGFloat = 78
    private let centerGap: CGFloat = 90

    var body: some View {
        ZStack(alignment: .top) {
            chassis
            glassFace
            topSpecular
            tabRow
            centerDial
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight)
        .padding(.horizontal, 7)
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

    private var chassis: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "F7F8F9"), location: 0.00),
                        .init(color: Color(hex: "A5ABB0"), location: 0.10),
                        .init(color: Color(hex: "E8EAEC"), location: 0.20),
                        .init(color: Color(hex: "565D63"), location: 0.54),
                        .init(color: Color(hex: "B4BAC0"), location: 0.78),
                        .init(color: Color(hex: "4A5056"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.82), Color(hex: "6C747B"), Color.white.opacity(0.24)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: .black.opacity(0.82), radius: 14, y: 7)
    }

    private var glassFace: some View {
        CanonicalNavShape()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "151B20"), location: 0.00),
                        .init(color: Color(hex: "090D10"), location: 0.34),
                        .init(color: Color(hex: "020304"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                CanonicalNavShape()
                    .stroke(MilliColors.cyanGlow.opacity(0.14), lineWidth: 0.65)
            }
            .scaleEffect(x: 0.985, y: 0.905, anchor: .bottom)
            .offset(y: 3)
            .allowsHitTesting(false)
    }

    private var topSpecular: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(0.55), Color.white.opacity(0.08), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 1)
            .padding(.horizontal, 24)
            .offset(y: 17)
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
        .padding(.horizontal, 7)
        .padding(.top, 25)
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
                    if isSelected {
                        Circle()
                            .fill(MilliColors.cyanGlow.opacity(0.075))
                            .frame(width: 31, height: 31)
                            .blur(radius: 1)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: tab == .cockpit ? 17 : 16, weight: .semibold))
                        .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "C2C7CC"))
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.34) : .clear, radius: 4)
                }
                .frame(height: 31)

                Text(tab.displayName)
                    .font(.custom("Inter-Medium", size: 10, relativeTo: .caption))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "A3AAB0"))
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
                                Color(hex: "F8F9FA"),
                                Color(hex: "666D74"),
                                Color(hex: "DEE2E5"),
                                Color(hex: "3E454B"),
                                Color(hex: "F4F6F7"),
                                Color(hex: "7B8289"),
                                Color(hex: "E8EBED")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: centerDiameter, height: centerDiameter)
                    .overlay { Circle().stroke(Color.white.opacity(0.64), lineWidth: 0.75) }
                    .shadow(color: .black.opacity(0.86), radius: 9, y: 5)

                Circle()
                    .fill(Color(hex: "05080A"))
                    .frame(width: centerDiameter - 9, height: centerDiameter - 9)
                    .overlay { Circle().stroke(Color.black.opacity(0.95), lineWidth: 1.2) }

                SegmentedArcRing(segments: 32, gapDegrees: 5.1)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3.0, lineCap: .butt)
                    )
                    .frame(width: centerDiameter - 17, height: centerDiameter - 17)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.44), radius: 4)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "182127"), Color(hex: "070A0D"), Color.black],
                            center: UnitPoint(x: 0.42, y: 0.30),
                            startRadius: 1,
                            endRadius: 31
                        )
                    )
                    .frame(width: centerDiameter - 29, height: centerDiameter - 29)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.48), Color(hex: "737B82"), Color.white.opacity(0.07)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    }

                MilliMMark(size: 36)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 4)
            }
            .scaleEffect(isDialPressed ? 0.965 : 1)
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
        let corner: CGFloat = 22
        let shoulder: CGFloat = 57
        let crestDepth: CGFloat = 16

        p.move(to: CGPoint(x: corner, y: crestDepth))
        p.addLine(to: CGPoint(x: center - shoulder, y: crestDepth))
        p.addCurve(
            to: CGPoint(x: center - 39, y: 4),
            control1: CGPoint(x: center - 51, y: crestDepth),
            control2: CGPoint(x: center - 47, y: 7)
        )
        p.addCurve(
            to: CGPoint(x: center, y: 0),
            control1: CGPoint(x: center - 26, y: 0),
            control2: CGPoint(x: center - 13, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: center + 39, y: 4),
            control1: CGPoint(x: center + 13, y: 0),
            control2: CGPoint(x: center + 26, y: 0)
        )
        p.addCurve(
            to: CGPoint(x: center + shoulder, y: crestDepth),
            control1: CGPoint(x: center + 47, y: 7),
            control2: CGPoint(x: center + 51, y: crestDepth)
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
