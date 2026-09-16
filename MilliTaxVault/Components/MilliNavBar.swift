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
        case .vault: return "PAYOUTS"
        case .activity: return "MILEAGE"
        case .wealth: return "WEALTH"
        case .cockpit: return "MORE"
        case .home: return "HOME"
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
// - Active tab: restrained cyan illumination. Inactive tabs: dark machined graphite for legibility on chrome.
// - Center control: refractive liquid-glass sphere with subtle internal fluid motion.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false
    @State private var liquidPhase = false

    private let deckHeight: CGFloat = 58
    private let lowerFaceHeight: CGFloat = 30
    private let crestHeight: CGFloat = 34
    private let safeAreaExtension: CGFloat = 44

    private var lowerFaceGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "14181D"), location: 0.0),
                .init(color: Color(hex: "07090B"), location: 0.6),
                .init(color: Color.black, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ChassisShape(crestHeight: crestHeight)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "E8EAED"), location: 0.0),
                            .init(color: Color(hex: "9BA1A8"), location: 0.35),
                            .init(color: Color(hex: "C6CAD0"), location: 0.65),
                            .init(color: Color(hex: "6E747B"), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    ChassisShape(crestHeight: crestHeight)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.85),
                                    Color(hex: "A0AAB2").opacity(0.55),
                                    Color.white.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(lowerFaceGradient)
                        .frame(height: lowerFaceHeight)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(0.10))
                                .frame(height: 0.5)
                        }
                }
                .shadow(color: Color.black.opacity(0.85), radius: 14, x: 0, y: -6)
                .frame(height: deckHeight + lowerFaceHeight)

            recessedDetails
                .allowsHitTesting(false)
                .frame(height: deckHeight + lowerFaceHeight, alignment: .top)
                .padding(.top, 10)
                .padding(.horizontal, 34)

            HStack(spacing: 0) {
                tabButton(.vault)
                tabButton(.activity)

                Spacer()
                    .frame(width: 96)

                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 10)
            .frame(height: deckHeight + lowerFaceHeight, alignment: .top)
            .padding(.top, 4)

            centerDialButton
                .offset(y: -crestHeight + 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: deckHeight + lowerFaceHeight + 12)
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
                        .font(.system(size: 19, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.white, MilliColors.cyanGlow],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color(hex: "30373D"))
                        )
                        .shadow(
                            color: isSelected
                                ? MilliColors.cyanGlow.opacity(0.45)
                                : Color.white.opacity(0.16),
                            radius: isSelected ? 4 : 0.5,
                            y: isSelected ? 0 : 0.5
                        )
                        .frame(height: 24)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "3C444B"))
                    .tracking(0.55)
                    .shadow(
                        color: isSelected ? MilliColors.cyanGlow.opacity(0.35) : Color.white.opacity(0.18),
                        radius: isSelected ? 3 : 0.5,
                        y: isSelected ? 0 : 0.5
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Recessed deck details

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
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 7, height: 7)
            .overlay(
                Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }

    // MARK: - Center M Liquid Glass Crest

    private var centerDialButton: some View {
        Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            ZStack {
                // Machined socket retained so the orb still belongs to the chassis.
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
                    .shadow(color: Color.black.opacity(0.92), radius: 9, x: 0, y: 6)

                Circle()
                    .fill(Color(hex: "020508"))
                    .frame(width: 71, height: 71)

                SegmentedArcRing(segments: 4, gapDegrees: 14)
                    .stroke(MilliColors.cyanGlow.opacity(0.82), lineWidth: 2.0)
                    .frame(width: 66, height: 66)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 3)

                // Refractive outer glass body.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color(hex: "5DEBFF").opacity(0.10),
                                Color(hex: "09131A").opacity(0.78),
                                Color.black.opacity(0.94)
                            ],
                            center: UnitPoint(x: 0.34, y: 0.27),
                            startRadius: 1,
                            endRadius: 34
                        )
                    )
                    .frame(width: 59, height: 59)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.92),
                                        Color.white.opacity(0.18),
                                        MilliColors.cyanGlow.opacity(0.52),
                                        Color.white.opacity(0.12)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.15
                            )
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 7)

                // Fluid volume: a dark cyan gel with a softly moving meniscus.
                ZStack {
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MilliColors.cyanGlow.opacity(0.26),
                                    MilliColors.deepCyan.opacity(0.42),
                                    Color(hex: "03151A").opacity(0.82)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 54, height: 38)
                        .offset(x: liquidPhase ? 1.8 : -1.8, y: liquidPhase ? 12.5 : 10.5)
                        .rotationEffect(.degrees(liquidPhase ? 2.2 : -2.2))

                    Ellipse()
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
                        .frame(width: 46, height: 9)
                        .offset(x: liquidPhase ? -1.2 : 1.2, y: liquidPhase ? -5.0 : -4.0)
                        .rotationEffect(.degrees(liquidPhase ? -2.5 : 2.5))

                    Circle()
                        .fill(Color.white.opacity(0.23))
                        .frame(width: 3.2, height: 3.2)
                        .offset(x: liquidPhase ? 12 : 9, y: liquidPhase ? 8 : 13)

                    Circle()
                        .fill(MilliColors.cyanGlow.opacity(0.30))
                        .frame(width: 2.4, height: 2.4)
                        .offset(x: liquidPhase ? -13 : -10, y: liquidPhase ? 15 : 10)
                }
                .frame(width: 55, height: 55)
                .clipShape(Circle())
                .allowsHitTesting(false)

                // Suspended M: dark extrusion behind the approved artwork creates thickness.
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 31, height: 31)
                    .opacity(0.52)
                    .offset(x: 1.6, y: 2.3)
                    .blur(radius: 0.35)
                    .accessibilityHidden(true)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 31, height: 31)
                    .shadow(color: Color.black.opacity(0.88), radius: 2, x: 0, y: 2)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.68), radius: 6)
                    .offset(y: liquidPhase ? -0.7 : 0.7)
                    .accessibilityHidden(true)

                // Upper glass caustic / lens reflection.
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.62),
                                Color.white.opacity(0.10),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 31, height: 13)
                    .rotationEffect(.degrees(-18))
                    .offset(x: -8, y: -16)
                    .blur(radius: 0.25)
                    .allowsHitTesting(false)

                // Cyan bounce from the liquid against the lower interior glass.
                Ellipse()
                    .fill(MilliColors.cyanGlow.opacity(0.16))
                    .frame(width: 37, height: 9)
                    .blur(radius: 3)
                    .offset(y: 21)
                    .allowsHitTesting(false)
            }
            .scaleEffect(isDialPressed ? 0.94 : 1.0)
            .offset(y: isDialPressed ? 1.5 : 0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isDialPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isDialPressed = true }
                .onEnded { _ in isDialPressed = false }
        )
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 3.8).repeatForever(autoreverses: true)) {
                liquidPhase = true
            }
        }
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
        let crestWidth: CGFloat = 96
        let crestCenter = w / 2
        let shoulderStart = crestCenter - crestWidth / 2
        let shoulderEnd = crestCenter + crestWidth / 2
        let deckY: CGFloat = 0

        path.move(to: CGPoint(x: 0, y: deckY))
        path.addLine(to: CGPoint(x: shoulderStart, y: deckY))
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
        path.addLine(to: CGPoint(x: w, y: deckY))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
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
