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
        case .vault: return "dollarsign.arrow.circlepath"
        case .activity: return "location.north.fill"
        case .wealth: return "chart.line.uptrend.xyaxis"
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
// LOCKED CANONICAL REFERENCE:
// - Full-width machined chrome chassis anchored to the screen edge.
// - Tall integrated center tower; the M dial is physically seated inside it.
// - Wide swept shoulders from the tower into the deck.
// - Four recessed fastener/details across the upper deck.
// - Bright polished upper surface + deep obsidian lower fascia.
// - Center M uses a segmented cyan illumination ring, never a continuous neon halo.
// - No floating capsule, no floating FAB, no geometry above the view's drawable bounds.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let totalHeight: CGFloat = 148
    private let deckTopY: CGFloat = 67
    private let lowerFaceHeight: CGFloat = 34
    private let safeAreaExtension: CGFloat = 44
    private let dialSize: CGFloat = 86

    private var chromeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "F7F8FA"), location: 0.00),
                .init(color: Color(hex: "D6D9DD"), location: 0.18),
                .init(color: Color(hex: "8F969E"), location: 0.45),
                .init(color: Color(hex: "D9DCE0"), location: 0.68),
                .init(color: Color(hex: "727A83"), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var lowerFaceGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "252C34"), location: 0.00),
                .init(color: Color(hex: "10151A"), location: 0.38),
                .init(color: Color(hex: "07090B"), location: 0.76),
                .init(color: Color.black, location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            CanonicalChassisShape(deckTopY: deckTopY)
                .fill(chromeGradient)
                .overlay {
                    CanonicalChassisShape(deckTopY: deckTopY)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.95), location: 0.00),
                                    .init(color: Color(hex: "AFB6BD").opacity(0.70), location: 0.36),
                                    .init(color: Color.white.opacity(0.42), location: 0.62),
                                    .init(color: Color(hex: "555D65").opacity(0.70), location: 1.00)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
                .overlay(alignment: .top) {
                    CanonicalTopHighlightShape(deckTopY: deckTopY)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.92),
                                    Color.white.opacity(0.30),
                                    Color(hex: "AAB2BA").opacity(0.58)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)
                        )
                        .padding(.horizontal, 1)
                }
                .shadow(color: Color.black.opacity(0.88), radius: 16, x: 0, y: -5)

            // The dark lower fascia is part of the same physical chassis, not a
            // separate floating bar. It begins below the controls and runs through
            // the home-indicator safe area.
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(lowerFaceGradient)
                    .frame(height: lowerFaceHeight)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(Color.white.opacity(0.16))
                            .frame(height: 0.7)
                    }
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.black.opacity(0.72))
                            .frame(height: 1)
                    }
            }
            .allowsHitTesting(false)

            recessedDetails
                .padding(.horizontal, 32)
                .offset(y: deckTopY + 5)
                .allowsHitTesting(false)

            HStack(spacing: 0) {
                tabButton(.vault)
                tabButton(.activity)

                Spacer()
                    .frame(width: 112)

                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 8)
            .offset(y: deckTopY + 14)

            centerDialButton
                .offset(y: 10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: totalHeight)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(lowerFaceGradient)
                .frame(height: safeAreaExtension)
                .offset(y: safeAreaExtension)
                .ignoresSafeArea(edges: .bottom)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Milli navigation")
    }

    // MARK: - Tab Item Button

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
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MilliColors.cyanGlow.opacity(0.24),
                                        MilliColors.cyanGlow.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 1,
                                    endRadius: 18
                                )
                            )
                            .frame(width: 34, height: 34)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: tab == .cockpit ? 18 : 19, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white, MilliColors.cyanGlow],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color(hex: "24303B"))
                        )
                        .shadow(
                            color: isSelected ? MilliColors.cyanGlow.opacity(0.48) : Color.white.opacity(0.10),
                            radius: isSelected ? 4 : 0.5,
                            y: isSelected ? 0 : 0.5
                        )
                        .frame(height: 23)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "2D3945"))
                    .tracking(0.55)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Recessed deck details

    private var recessedDetails: some View {
        HStack(spacing: 0) {
            recessedDot
            Spacer()
            recessedDot
            Spacer().frame(width: 126)
            recessedDot
            Spacer()
            recessedDot
        }
    }

    private var recessedDot: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.34))
                .frame(width: 10, height: 10)
                .blur(radius: 0.2)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "3B444E"),
                            Color(hex: "11161C"),
                            Color.black
                        ],
                        center: .topLeading,
                        startRadius: 1,
                        endRadius: 7
                    )
                )
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 0.5))
        }
        .shadow(color: Color.black.opacity(0.72), radius: 1.5, y: 1)
    }

    // MARK: - Center M Tower Dial

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
                                Color(hex: "FBFCFD"),
                                Color(hex: "7D858E"),
                                Color(hex: "E9EDF1"),
                                Color(hex: "4D555E"),
                                Color(hex: "D8DEE4"),
                                Color(hex: "737C86"),
                                Color(hex: "FFFFFF")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: dialSize, height: dialSize)
                    .overlay(Circle().stroke(Color.white.opacity(0.64), lineWidth: 0.8))
                    .shadow(color: Color.black.opacity(0.90), radius: 9, x: 0, y: 5)

                Circle()
                    .fill(Color(hex: "070A0D"))
                    .frame(width: dialSize - 8, height: dialSize - 8)

                SegmentedArcRing(segments: 8, gapDegrees: 18)
                    .stroke(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                    )
                    .frame(width: dialSize - 15, height: dialSize - 15)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.52), radius: 4)

                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color.white.opacity(0.82),
                                Color(hex: "79828B").opacity(0.55),
                                Color.white.opacity(0.48),
                                Color(hex: "59616A").opacity(0.55),
                                Color.white.opacity(0.82)
                            ],
                            center: .center
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: dialSize - 27, height: dialSize - 27)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "19212A"),
                                Color(hex: "0B0F14"),
                                Color.black
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 30
                        )
                    )
                    .frame(width: dialSize - 32, height: dialSize - 32)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 39, height: 39)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.62), radius: 6)
            }
            .frame(width: dialSize, height: dialSize)
            .scaleEffect(isDialPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isDialPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isDialPressed = true }
                .onEnded { _ in isDialPressed = false }
        )
        .accessibilityLabel("Home")
        .accessibilityHint("Navigates to the Milli Home cockpit")
    }
}

// MARK: - Canonical chassis silhouette

/// Draws the full locked silhouette *inside* its rect. The previous implementation
/// attempted to put the crest at negative Y, which caused SwiftUI to clip the tower
/// and visually reduced the nav to a flat silver shelf.
struct CanonicalChassisShape: Shape {
    let deckTopY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let center = w / 2

        let topY: CGFloat = 2
        let towerTopHalfWidth: CGFloat = 55
        let towerFootHalfWidth: CGFloat = 78
        let shoulderRun: CGFloat = 74

        let leftShoulderStart = center - towerFootHalfWidth - shoulderRun
        let leftFoot = center - towerFootHalfWidth
        let leftTop = center - towerTopHalfWidth
        let rightTop = center + towerTopHalfWidth
        let rightFoot = center + towerFootHalfWidth
        let rightShoulderEnd = center + towerFootHalfWidth + shoulderRun

        path.move(to: CGPoint(x: 0, y: deckTopY))
        path.addLine(to: CGPoint(x: leftShoulderStart, y: deckTopY))

        // Broad left shoulder sweep into the raised central tower.
        path.addCurve(
            to: CGPoint(x: leftFoot, y: deckTopY - 20),
            control1: CGPoint(x: leftShoulderStart + 30, y: deckTopY),
            control2: CGPoint(x: leftFoot - 20, y: deckTopY - 7)
        )
        path.addLine(to: CGPoint(x: leftTop, y: topY + 18))
        path.addCurve(
            to: CGPoint(x: leftTop + 11, y: topY),
            control1: CGPoint(x: leftTop + 1, y: topY + 9),
            control2: CGPoint(x: leftTop + 5, y: topY + 2)
        )

        // Flat machined crown behind the center M housing.
        path.addLine(to: CGPoint(x: rightTop - 11, y: topY))
        path.addCurve(
            to: CGPoint(x: rightTop, y: topY + 18),
            control1: CGPoint(x: rightTop - 5, y: topY + 2),
            control2: CGPoint(x: rightTop - 1, y: topY + 9)
        )
        path.addLine(to: CGPoint(x: rightFoot, y: deckTopY - 20))

        // Broad right shoulder sweep back into the full-width deck.
        path.addCurve(
            to: CGPoint(x: rightShoulderEnd, y: deckTopY),
            control1: CGPoint(x: rightFoot + 20, y: deckTopY - 7),
            control2: CGPoint(x: rightShoulderEnd - 30, y: deckTopY)
        )

        path.addLine(to: CGPoint(x: w, y: deckTopY))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

/// Highlights only the upper machined edge so the silhouette reads as a thick
/// polished hardware object rather than a flat gradient panel.
struct CanonicalTopHighlightShape: Shape {
    let deckTopY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let center = w / 2
        let topY: CGFloat = 2
        let towerTopHalfWidth: CGFloat = 55
        let towerFootHalfWidth: CGFloat = 78
        let shoulderRun: CGFloat = 74
        let leftShoulderStart = center - towerFootHalfWidth - shoulderRun
        let leftFoot = center - towerFootHalfWidth
        let leftTop = center - towerTopHalfWidth
        let rightTop = center + towerTopHalfWidth
        let rightFoot = center + towerFootHalfWidth
        let rightShoulderEnd = center + towerFootHalfWidth + shoulderRun

        path.move(to: CGPoint(x: 0, y: deckTopY))
        path.addLine(to: CGPoint(x: leftShoulderStart, y: deckTopY))
        path.addCurve(
            to: CGPoint(x: leftFoot, y: deckTopY - 20),
            control1: CGPoint(x: leftShoulderStart + 30, y: deckTopY),
            control2: CGPoint(x: leftFoot - 20, y: deckTopY - 7)
        )
        path.addLine(to: CGPoint(x: leftTop, y: topY + 18))
        path.addCurve(
            to: CGPoint(x: leftTop + 11, y: topY),
            control1: CGPoint(x: leftTop + 1, y: topY + 9),
            control2: CGPoint(x: leftTop + 5, y: topY + 2)
        )
        path.addLine(to: CGPoint(x: rightTop - 11, y: topY))
        path.addCurve(
            to: CGPoint(x: rightTop, y: topY + 18),
            control1: CGPoint(x: rightTop - 5, y: topY + 2),
            control2: CGPoint(x: rightTop - 1, y: topY + 9)
        )
        path.addLine(to: CGPoint(x: rightFoot, y: deckTopY - 20))
        path.addCurve(
            to: CGPoint(x: rightShoulderEnd, y: deckTopY),
            control1: CGPoint(x: rightFoot + 20, y: deckTopY - 7),
            control2: CGPoint(x: rightShoulderEnd - 30, y: deckTopY)
        )
        path.addLine(to: CGPoint(x: w, y: deckTopY))
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
        let arcAngle = max(segmentAngle - gapDegrees, 2)

        for i in 0..<segments {
            let start = Angle.degrees(Double(i) * Double(segmentAngle) - 90 + Double(gapDegrees) / 2)
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

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()

        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.activity))
        }
    }
}