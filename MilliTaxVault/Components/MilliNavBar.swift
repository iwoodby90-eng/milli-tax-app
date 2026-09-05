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
// - Controlled swept shoulders from the tower into the deck.
// - Four recessed fastener/details across the upper deck.
// - Bright polished upper surface + deep obsidian lower fascia.
// - Center M uses discrete cyan illumination ticks, never a continuous neon halo.
// - No floating capsule, no floating FAB, no geometry above the view's drawable bounds.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let totalHeight: CGFloat = 146
    private let deckTopY: CGFloat = 72
    private let lowerFaceHeight: CGFloat = 28
    private let safeAreaExtension: CGFloat = 44
    private let dialSize: CGFloat = 78

    private var chromeGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "F8F9FA"), location: 0.00),
                .init(color: Color(hex: "DBDEE2"), location: 0.17),
                .init(color: Color(hex: "9299A1"), location: 0.43),
                .init(color: Color(hex: "DEE1E5"), location: 0.67),
                .init(color: Color(hex: "767E87"), location: 1.00)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var lowerFaceGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "232A31"), location: 0.00),
                .init(color: Color(hex: "11161B"), location: 0.38),
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
                                    .init(color: Color.white.opacity(0.96), location: 0.00),
                                    .init(color: Color(hex: "AFB6BD").opacity(0.72), location: 0.36),
                                    .init(color: Color.white.opacity(0.44), location: 0.62),
                                    .init(color: Color(hex: "555D65").opacity(0.72), location: 1.00)
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
                                    Color.white.opacity(0.94),
                                    Color.white.opacity(0.32),
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

            // Dark lower fascia is physically integrated into the same chassis.
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
                .offset(y: deckTopY + 4)
                .allowsHitTesting(false)

            HStack(spacing: 0) {
                tabButton(.vault)
                tabButton(.activity)

                Spacer()
                    .frame(width: 104)

                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 8)
            .offset(y: deckTopY + 1)

            centerDialButton
                .offset(y: 8)
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
            VStack(spacing: 2) {
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
                            .frame(width: 32, height: 32)
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
                                : AnyShapeStyle(Color(hex: "263440"))
                        )
                        .shadow(
                            color: isSelected ? MilliColors.cyanGlow.opacity(0.48) : Color.white.opacity(0.10),
                            radius: isSelected ? 4 : 0.5,
                            y: isSelected ? 0 : 0.5
                        )
                        .frame(height: 22)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "33414D"))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
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
            Spacer().frame(width: 116)
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
                    .overlay(Circle().stroke(Color.white.opacity(0.66), lineWidth: 0.8))
                    .shadow(color: Color.black.opacity(0.90), radius: 8, x: 0, y: 5)

                Circle()
                    .fill(Color(hex: "070A0D"))
                    .frame(width: dialSize - 7, height: dialSize - 7)

                CanonicalTickRing(size: dialSize - 12, tickCount: 40)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.46), radius: 3)

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
                        lineWidth: 1.1
                    )
                    .frame(width: dialSize - 24, height: dialSize - 24)

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
                            endRadius: 27
                        )
                    )
                    .frame(width: dialSize - 29, height: dialSize - 29)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .blendMode(.screen)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 4)
                    .accessibilityHidden(true)
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

/// Draws the full locked silhouette inside its rect. The former implementation
/// placed its crest at negative Y and SwiftUI clipped the signature center tower.
struct CanonicalChassisShape: Shape {
    let deckTopY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let center = w / 2

        let topY: CGFloat = 2
        let towerTopHalfWidth: CGFloat = 49
        let towerFootHalfWidth: CGFloat = 66
        let shoulderRun: CGFloat = 42

        let leftShoulderStart = center - towerFootHalfWidth - shoulderRun
        let leftFoot = center - towerFootHalfWidth
        let leftTop = center - towerTopHalfWidth
        let rightTop = center + towerTopHalfWidth
        let rightFoot = center + towerFootHalfWidth
        let rightShoulderEnd = center + towerFootHalfWidth + shoulderRun

        path.move(to: CGPoint(x: 0, y: deckTopY))
        path.addLine(to: CGPoint(x: leftShoulderStart, y: deckTopY))

        path.addCurve(
            to: CGPoint(x: leftFoot, y: deckTopY - 17),
            control1: CGPoint(x: leftShoulderStart + 18, y: deckTopY),
            control2: CGPoint(x: leftFoot - 13, y: deckTopY - 6)
        )
        path.addLine(to: CGPoint(x: leftTop, y: topY + 17))
        path.addCurve(
            to: CGPoint(x: leftTop + 10, y: topY),
            control1: CGPoint(x: leftTop + 1, y: topY + 8),
            control2: CGPoint(x: leftTop + 5, y: topY + 2)
        )

        path.addLine(to: CGPoint(x: rightTop - 10, y: topY))
        path.addCurve(
            to: CGPoint(x: rightTop, y: topY + 17),
            control1: CGPoint(x: rightTop - 5, y: topY + 2),
            control2: CGPoint(x: rightTop - 1, y: topY + 8)
        )
        path.addLine(to: CGPoint(x: rightFoot, y: deckTopY - 17))

        path.addCurve(
            to: CGPoint(x: rightShoulderEnd, y: deckTopY),
            control1: CGPoint(x: rightFoot + 13, y: deckTopY - 6),
            control2: CGPoint(x: rightShoulderEnd - 18, y: deckTopY)
        )

        path.addLine(to: CGPoint(x: w, y: deckTopY))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

/// Machined specular edge tracing the exact top silhouette.
struct CanonicalTopHighlightShape: Shape {
    let deckTopY: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let center = w / 2
        let topY: CGFloat = 2
        let towerTopHalfWidth: CGFloat = 49
        let towerFootHalfWidth: CGFloat = 66
        let shoulderRun: CGFloat = 42
        let leftShoulderStart = center - towerFootHalfWidth - shoulderRun
        let leftFoot = center - towerFootHalfWidth
        let leftTop = center - towerTopHalfWidth
        let rightTop = center + towerTopHalfWidth
        let rightFoot = center + towerFootHalfWidth
        let rightShoulderEnd = center + towerFootHalfWidth + shoulderRun

        path.move(to: CGPoint(x: 0, y: deckTopY))
        path.addLine(to: CGPoint(x: leftShoulderStart, y: deckTopY))
        path.addCurve(
            to: CGPoint(x: leftFoot, y: deckTopY - 17),
            control1: CGPoint(x: leftShoulderStart + 18, y: deckTopY),
            control2: CGPoint(x: leftFoot - 13, y: deckTopY - 6)
        )
        path.addLine(to: CGPoint(x: leftTop, y: topY + 17))
        path.addCurve(
            to: CGPoint(x: leftTop + 10, y: topY),
            control1: CGPoint(x: leftTop + 1, y: topY + 8),
            control2: CGPoint(x: leftTop + 5, y: topY + 2)
        )
        path.addLine(to: CGPoint(x: rightTop - 10, y: topY))
        path.addCurve(
            to: CGPoint(x: rightTop, y: topY + 17),
            control1: CGPoint(x: rightTop - 5, y: topY + 2),
            control2: CGPoint(x: rightTop - 1, y: topY + 8)
        )
        path.addLine(to: CGPoint(x: rightFoot, y: deckTopY - 17))
        path.addCurve(
            to: CGPoint(x: rightShoulderEnd, y: deckTopY),
            control1: CGPoint(x: rightFoot + 13, y: deckTopY - 6),
            control2: CGPoint(x: rightShoulderEnd - 18, y: deckTopY)
        )
        path.addLine(to: CGPoint(x: w, y: deckTopY))
        return path
    }
}

// MARK: - Center illumination

/// Static discrete cyan ticks matching the locked hardware reference. No pulse.
struct CanonicalTickRing: View {
    let size: CGFloat
    let tickCount: Int

    var body: some View {
        let radius = size / 2 - 2

        ZStack {
            ForEach(0..<tickCount, id: \.self) { index in
                let angle = (Double(index) / Double(tickCount)) * 360.0

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [MilliColors.cyanGlow, MilliColors.deepCyan],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1.5, height: 4.0)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(angle))
            }
        }
        .frame(width: size, height: size)
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