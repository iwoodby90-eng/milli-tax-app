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
        case .vault: return "lock.shield.fill"
        case .activity: return "waveform.path.ecg"
        case .wealth: return "chart.bar.xaxis"
        case .cockpit: return "gauge.open.with.lines.needle.33percent"
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
// Canonical MILLI navigation (locked reference, Image 40):
// - Full-width sculpted metallic chassis integrated into the screen edge (NOT a floating capsule)
// - Signature silhouette: flat deck -> upward sweeping shoulder -> center M crest -> downward shoulder -> flat deck
// - Broad polished silver/chrome upper deck with visible depth; deep obsidian black-glass lower face
// - Four circular recessed details across the upper deck: two left, two right
// - Center M physically integrated into the chassis crest (never a floating FAB)
// - Segmented cyan illumination arcs with dark spacers (never a continuous ring)
// - Active tab: restrained cyan illumination. Inactive tabs: silver/graphite.
// - Motion: static active-state illumination only; no glow cycling or pulsing.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false

    private let deckHeight: CGFloat = 58
    private let lowerFaceHeight: CGFloat = 30
    private let crestHeight: CGFloat = 34

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-width chassis: lower obsidian face + upper chrome deck + shoulder silhouette
            ChassisShape(crestHeight: crestHeight)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "E8EAED"), location: 0.0),
                            .init(color: Color(hex: "9BA1A8"), location: 0.35),
                            .init(color: Color(hex: "C6CAD0"), location: 0.65),
                            .init(color: Color(hex: "6E747B"), location: 1.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    // Upper-deck machined seam
                    ChassisShape(crestHeight: crestHeight)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color(hex: "A0AAB2").opacity(0.55),
                                    Color.white.opacity(0.35)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .overlay(alignment: .bottom) {
                    // Deep obsidian black-glass lower face
                    RoundedRectangle(cornerRadius: 0)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: "14181D"), location: 0.0),
                                    .init(color: Color(hex: "07090B"), location: 0.6),
                                    .init(color: Color.black, location: 1.0)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(height: lowerFaceHeight)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
                        )
                }
                .shadow(color: Color.black.opacity(0.85), radius: 14, x: 0, y: -6)
                .frame(height: deckHeight + lowerFaceHeight)

            // Four recessed circular details across the upper deck: two left, two right
            recessedDetails
                .allowsHitTesting(false)
                .frame(height: deckHeight + lowerFaceHeight, alignment: .top)
                .padding(.top, 10)
                .padding(.horizontal, 34)

            // Tab destinations + recessed details + center M crest
            HStack(spacing: 0) {
                // Left group: Payouts & Mileage
                tabButton(.vault)
                tabButton(.activity)

                Spacer()
                    .frame(width: 96)

                // Right group: Wealth & More
                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 10)
            .frame(height: deckHeight + lowerFaceHeight, alignment: .top)
            .padding(.top, 4)

            // Center M crest, integrated into the chassis (no floating elevation)
            centerDialButton
                .offset(y: -crestHeight + 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: deckHeight + lowerFaceHeight + 12)
        .padding(.bottom, 0)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Milli navigation")
    }

    // MARK: - Tab Item Button

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        // Restrained embedded cyan illumination (static, no cycling)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MilliColors.cyanGlow.opacity(0.28),
                                        MilliColors.cyanGlow.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 36, height: 36)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white, MilliColors.cyanGlow],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color(hex: "959E9F"))
                        )
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.45) : .clear, radius: 4)
                        .frame(height: 24)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-Medium", size: 10, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : MilliColors.textSecondary)
                    .tracking(0.3)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.35) : .clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Recessed deck details (two left, two right)

    private var recessedDetails: some View {
        HStack(spacing: 26) {
            ForEach(0..<2, id: \.self) { _ in recessedDot }
            Spacer().frame(width: 150)
            ForEach(0..<2, id: \.self) { _ in recessedDot }
        }
    }

    private var recessedDot: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(hex: "2A2F35"),
                        Color(hex: "0C0F12")
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: 7, height: 7)
            .overlay(
                Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }

    // MARK: - Center M Crest Dial (Home), integrated into the chassis

    private var centerDialButton: some View {
        Button {
            selectedTab = .home
            onHomeTap()
        } label: {
            ZStack {
                // Sculpted chrome outer housing
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(hex: "F4F7FA"),
                                Color(hex: "757D87"),
                                Color(hex: "DFE4EA"),
                                Color(hex: "2F353F"),
                                Color(hex: "CBD2D9"),
                                Color(hex: "666E78"),
                                Color(hex: "F8FAFC")
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 78, height: 78)
                    .shadow(color: Color.black.opacity(0.9), radius: 8, x: 0, y: 5)

                // Dark mechanical groove
                Circle()
                    .fill(Color(hex: "05080B"))
                    .frame(width: 70, height: 70)

                // Segmented cyan illumination arcs (4 arcs with dark spacers, never continuous)
                SegmentedArcRing(segments: 4, gapDegrees: 14)
                    .stroke(MilliColors.cyanGlow.opacity(0.85), lineWidth: 2.2)
                    .frame(width: 62, height: 62)

                // Secondary metallic ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.75), Color(hex: "8A929B").opacity(0.5)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                    .frame(width: 55, height: 55)

                // Black-glass face
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "141A22"),
                                Color(hex: "080B0E"),
                                Color.black
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)

                // Dimensional metallic/cyan M emblem
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 5)
            }
            .scaleEffect(isDialPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.7), value: isDialPressed)
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

// MARK: - Chassis silhouette
// Flat deck -> upward sweeping shoulder -> center M crest -> downward sweeping shoulder -> flat deck.

struct ChassisShape: Shape {
    var crestHeight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let crestWidth: CGFloat = 96
        let crestCenter = w / 2
        let shoulderStart = crestCenter - crestWidth / 2
        let shoulderEnd = crestCenter + crestWidth / 2
        let deckY: CGFloat = 0

        path.move(to: CGPoint(x: 0, y: deckY))
        path.addLine(to: CGPoint(x: shoulderStart, y: deckY))
        // Upward sweeping shoulder (smooth curve into the crest)
        path.addCurve(
            to: CGPoint(x: crestCenter, y: deckY - crestHeight),
            control1: CGPoint(x: shoulderStart + crestWidth * 0.35, y: deckY),
            control2: CGPoint(x: shoulderStart + crestWidth * 0.35, y: deckY - crestHeight)
        )
        path.addCurve(
            to: CGPoint(x: shoulderEnd, y: deckY),
            control1: CGPoint(x: shoulderEnd - crestWidth * 0.35, y: deckY - crestHeight),
            control2: CGPoint(x: shoulderEnd - crestWidth * 0.35, y: deckY)
        )
        // Flat deck to the right edge, then down and around
        path.addLine(to: CGPoint(x: w, y: deckY))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

// MARK: - Segmented arc ring (cyan illumination with dark spacers)

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

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "07090B").ignoresSafeArea()

        VStack {
            Spacer()
            MilliNavBar(selectedTab: .constant(.home))
        }
    }
}