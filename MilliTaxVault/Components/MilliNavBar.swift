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
        case .wealth: return "dollarsign.circle.fill"
        case .cockpit: return "ellipsis"
        case .home: return ""
        }
    }

    var displayName: String {
        switch self {
        case .vault: return "PAYOUTS"
        case .activity: return "MILEAGE"
        case .wealth: return "WEALTH"
        case .cockpit: return "MORE"
        case .home: return "HOME"
        }
    }
}

// MARK: - MilliNavBar
// Canonical MILLI navigation based on the approved sculpted reference:
// polished chrome chassis, glossy obsidian face, four recessed instrument wells,
// an integrated center crest with a large segmented-cyan M dial, and no generic
// flat tab-bar treatment.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let chassisHeight: CGFloat = 124
    private let crestHeight: CGFloat = 38
    private let safeAreaExtension: CGFloat = 36

    var body: some View {
        ZStack(alignment: .top) {
            chassis
            blackGlassFace
            tabRow
            centerDialButton
        }
        .frame(maxWidth: .infinity)
        .frame(height: chassisHeight)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color.black)
                .frame(height: safeAreaExtension)
                .offset(y: safeAreaExtension)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Milli navigation")
    }

    private var chassis: some View {
        ChassisShape(crestHeight: crestHeight)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "F5F7F9"), location: 0.00),
                        .init(color: Color(hex: "A7ADB5"), location: 0.18),
                        .init(color: Color(hex: "E5E8EB"), location: 0.38),
                        .init(color: Color(hex: "7E858E"), location: 0.67),
                        .init(color: Color(hex: "C7CCD2"), location: 0.88),
                        .init(color: Color(hex: "666D75"), location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                ChassisShape(crestHeight: crestHeight)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.94), Color(hex: "9DA4AC"), Color.white.opacity(0.30)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            .overlay(alignment: .top) {
                ChassisShape(crestHeight: crestHeight)
                    .stroke(Color.white.opacity(0.22), lineWidth: 3.5)
                    .blur(radius: 1.2)
                    .offset(y: 2)
                    .mask(
                        LinearGradient(
                            colors: [.white, .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .shadow(color: .black.opacity(0.88), radius: 18, y: 8)
            .frame(height: chassisHeight)
    }

    private var blackGlassFace: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "1B2026"), location: 0.00),
                        .init(color: Color(hex: "090C10"), location: 0.36),
                        .init(color: Color.black, location: 1.00)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.30), Color.white.opacity(0.08), Color.black.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.16), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .padding(.horizontal, 7)
            .frame(height: 78)
            .offset(y: 43)
            .shadow(color: .black.opacity(0.72), radius: 5, y: 3)
            .allowsHitTesting(false)
    }

    private var tabRow: some View {
        HStack(spacing: 0) {
            tabButton(.vault)
            tabButton(.activity)

            Spacer()
                .frame(width: 112)

            tabButton(.wealth)
            tabButton(.cockpit)
        }
        .padding(.horizontal, 8)
        .frame(height: 82, alignment: .top)
        .offset(y: 35)
    }

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            selectedTab = tab
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    recessedInstrumentWell(active: isSelected)

                    Image(systemName: tab.icon)
                        .font(.system(size: tab == .cockpit ? 19 : 20, weight: .bold))
                        .foregroundStyle(
                            isSelected
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "A6FAFF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "D0D3D7"), Color(hex: "777E87")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        )
                        .shadow(
                            color: isSelected ? MilliColors.cyanGlow.opacity(0.58) : .black.opacity(0.55),
                            radius: isSelected ? 5 : 1,
                            y: 1
                        )
                }
                .frame(height: 43)

                Text(tab.displayName)
                    .font(.custom("Inter-SemiBold", size: 10.5, relativeTo: .caption))
                    .tracking(0.45)
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "8E959D"))
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.35) : .clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func recessedInstrumentWell(active: Bool) -> some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "F0F2F4"), Color(hex: "777D85"), Color(hex: "D0D4D8")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 55, height: 31)
                .shadow(color: .black.opacity(0.85), radius: 2, y: 2)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "262C32"), Color(hex: "090C0F"), Color.black],
                        center: UnitPoint(x: 0.46, y: 0.38),
                        startRadius: 1,
                        endRadius: 27
                    )
                )
                .frame(width: 47, height: 23)
                .overlay {
                    Ellipse()
                        .stroke(
                            active ? MilliColors.cyanGlow.opacity(0.72) : Color.white.opacity(0.13),
                            lineWidth: active ? 1.3 : 0.7
                        )
                }
                .shadow(color: active ? MilliColors.cyanGlow.opacity(0.25) : .clear, radius: 5)
        }
    }

    // MARK: Center M crest dial

    private var centerDialButton: some View {
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
                                Color(hex: "F7F9FB"),
                                Color(hex: "686F78"),
                                Color(hex: "DDE2E7"),
                                Color(hex: "3C434B"),
                                Color(hex: "F4F6F8"),
                                Color(hex: "777F88"),
                                Color(hex: "ECEFF2")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 104, height: 104)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.60), lineWidth: 0.9)
                    }
                    .shadow(color: .black.opacity(0.92), radius: 10, y: 7)

                Circle()
                    .fill(Color(hex: "11161B"))
                    .frame(width: 94, height: 94)
                    .overlay {
                        Circle().stroke(Color.black.opacity(0.9), lineWidth: 2)
                    }

                SegmentedArcRing(segments: 6, gapDegrees: 11)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4.2, lineCap: .butt)
                    )
                    .frame(width: 82, height: 82)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.42), radius: 6)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "172027"), Color(hex: "080B0E"), Color.black],
                            center: UnitPoint(x: 0.42, y: 0.32),
                            startRadius: 1,
                            endRadius: 36
                        )
                    )
                    .frame(width: 69, height: 69)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.55), Color(hex: "7B838C"), Color.white.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }

                MilliMMark(size: 45)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.48), radius: 6)
            }
            .scaleEffect(isDialPressed ? 0.955 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isDialPressed)
        }
        .buttonStyle(.plain)
        .offset(y: 2)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isDialPressed = true }
                .onEnded { _ in isDialPressed = false }
        )
        .accessibilityLabel("Home")
        .accessibilityHint("Navigates to the Milli Home cockpit")
    }
}

// MARK: - Chassis silhouette

struct ChassisShape: Shape {
    var crestHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let center = w / 2
        let crestHalfWidth: CGFloat = 64
        let shoulderOuter: CGFloat = 112
        let deckY = crestHeight + 10
        let cornerRadius: CGFloat = 28

        path.move(to: CGPoint(x: 0, y: deckY + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: deckY),
            control: CGPoint(x: 0, y: deckY)
        )

        path.addLine(to: CGPoint(x: center - shoulderOuter, y: deckY))
        path.addCurve(
            to: CGPoint(x: center - crestHalfWidth, y: 18),
            control1: CGPoint(x: center - 90, y: deckY),
            control2: CGPoint(x: center - 82, y: 18)
        )
        path.addCurve(
            to: CGPoint(x: center, y: 0),
            control1: CGPoint(x: center - 46, y: 7),
            control2: CGPoint(x: center - 22, y: 0)
        )
        path.addCurve(
            to: CGPoint(x: center + crestHalfWidth, y: 18),
            control1: CGPoint(x: center + 22, y: 0),
            control2: CGPoint(x: center + 46, y: 7)
        )
        path.addCurve(
            to: CGPoint(x: center + shoulderOuter, y: deckY),
            control1: CGPoint(x: center + 82, y: 18),
            control2: CGPoint(x: center + 90, y: deckY)
        )

        path.addLine(to: CGPoint(x: w - cornerRadius, y: deckY))
        path.addQuadCurve(
            to: CGPoint(x: w, y: deckY + cornerRadius),
            control: CGPoint(x: w, y: deckY)
        )
        path.addLine(to: CGPoint(x: w, y: h - 18))
        path.addQuadCurve(
            to: CGPoint(x: w - 18, y: h),
            control: CGPoint(x: w, y: h)
        )
        path.addLine(to: CGPoint(x: 18, y: h))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - 18),
            control: CGPoint(x: 0, y: h)
        )
        path.closeSubpath()
        return path
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
        let segmentAngle = 360.0 / CGFloat(segments)
        let arcAngle = segmentAngle - gapDegrees

        for i in 0..<segments {
            let start = Angle.degrees(Double(i) * Double(segmentAngle) - 90 - Double(gapDegrees) / 2)
            let end = start + .degrees(Double(arcAngle))
            path.addArc(
                center: center,
                radius: radius,
                startAngle: start,
                endAngle: end,
                clockwise: false
            )
        }
        return path
    }
}

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()

        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.home))
        }
    }
}
