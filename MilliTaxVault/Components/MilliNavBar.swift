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
// Canonical MILLI navigation chassis remains visually locked. Presence motion is
// confined to the integrated center M so the approved deck geometry never moves.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @EnvironmentObject private var milliPresence: MilliPresence
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isDialPressed = false
    @State private var ringRotation: Double = 0
    @State private var counterRotation: Double = 0
    @State private var celebrationLift: CGFloat = 0
    @State private var celebrationScale: CGFloat = 1

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

                Spacer().frame(width: 96)

                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 10)
            .frame(height: deckHeight + lowerFaceHeight, alignment: .top)
            .padding(.top, 4)

            centerDialButton
                .offset(y: -crestHeight + 6 + celebrationLift)
                .scaleEffect(celebrationScale)
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
        .onAppear { updatePresenceMotion(for: milliPresence.state) }
        .onChange(of: milliPresence.state) { _, newState in
            updatePresenceMotion(for: newState)
        }
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
                            .fill(RadialGradient(colors: [MilliColors.cyanGlow.opacity(0.28), MilliColors.cyanGlow.opacity(0.0)], center: .center, startRadius: 2, endRadius: 20))
                            .frame(width: 36, height: 36)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(colors: [Color.white, MilliColors.cyanGlow], startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color(hex: "30373D"))
                        )
                        .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.45) : Color.white.opacity(0.16), radius: isSelected ? 4 : 0.5, y: isSelected ? 0 : 0.5)
                        .frame(height: 24)
                }

                Text(tab.displayName)
                    .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                    .foregroundStyle(isSelected ? MilliColors.cyanGlow : Color(hex: "3C444B"))
                    .tracking(0.55)
                    .shadow(color: isSelected ? MilliColors.cyanGlow.opacity(0.35) : Color.white.opacity(0.18), radius: isSelected ? 3 : 0.5, y: isSelected ? 0 : 0.5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var recessedDetails: some View {
        HStack(spacing: 26) {
            ForEach(0..<2, id: \.self) { _ in recessedDot }
            Spacer().frame(width: 150)
            ForEach(0..<2, id: \.self) { _ in recessedDot }
        }
    }

    private var recessedDot: some View {
        Circle()
            .fill(LinearGradient(colors: [Color(hex: "2A2F35"), Color(hex: "0C0F12")], startPoint: .top, endPoint: .bottom))
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 1)
    }

    // MARK: - Center M Crest Dial

    private var centerDialButton: some View {
        Button {
            selectedTab = .home
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            ZStack {
                Circle()
                    .fill(AngularGradient(colors: [Color(hex: "F4F7FA"), Color(hex: "757D87"), Color(hex: "DFE4EA"), Color(hex: "2F353F"), Color(hex: "CBD2D9"), Color(hex: "666E78"), Color(hex: "F8FAFC")], center: .center))
                    .frame(width: 78, height: 78)
                    .shadow(color: Color.black.opacity(0.9), radius: 8, x: 0, y: 5)

                Circle()
                    .fill(Color(hex: "05080B"))
                    .frame(width: 70, height: 70)

                if milliPresence.state == .celebration || milliPresence.state == .success {
                    SegmentedArcRing(segments: 8, gapDegrees: 9)
                        .stroke(MilliColors.chromeWhite.opacity(0.72), lineWidth: 1.4)
                        .frame(width: 67, height: 67)
                        .rotationEffect(.degrees(counterRotation))
                }

                SegmentedArcRing(segments: ringSegmentCount, gapDegrees: ringGapDegrees)
                    .stroke(ringColor, lineWidth: ringLineWidth)
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(ringRotation))
                    .shadow(color: ringGlowColor, radius: ringGlowRadius)

                directionalIndicator

                Circle()
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.75), Color(hex: "8A929B").opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.0)
                    .frame(width: 55, height: 55)

                Circle()
                    .fill(RadialGradient(colors: [Color(hex: "141A22"), Color(hex: "080B0E"), Color.black], center: .center, startRadius: 1, endRadius: 25))
                    .frame(width: 50, height: 50)

                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .shadow(color: MilliColors.cyanGlow.opacity(milliPresence.state == .idle ? 0.55 : 0.92), radius: milliPresence.state == .idle ? 5 : 9)
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

    @ViewBuilder
    private var directionalIndicator: some View {
        switch milliPresence.state {
        case .turnLeft:
            Image(systemName: "arrow.turn.up.left")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MilliColors.cyanGlow)
                .offset(x: -23)
        case .turnRight:
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(MilliColors.cyanGlow)
                .offset(x: 23)
        case .rerouting:
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(MilliColors.cyanGlow)
                .offset(y: -23)
        case .arriving:
            Image(systemName: "flag.checkered")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(MilliColors.positive)
                .offset(y: -23)
        default:
            EmptyView()
        }
    }

    private var ringSegmentCount: Int {
        switch milliPresence.state {
        case .celebration: return 12
        case .speaking, .navigating, .turnLeft, .turnRight, .rerouting, .arriving: return 8
        default: return 4
        }
    }

    private var ringGapDegrees: CGFloat {
        milliPresence.state == .celebration ? 7 : 14
    }

    private var ringLineWidth: CGFloat {
        switch milliPresence.state {
        case .celebration: return 3.0
        case .success, .speaking, .navigating, .turnLeft, .turnRight, .rerouting, .arriving: return 2.6
        default: return 2.2
        }
    }

    private var ringColor: Color {
        switch milliPresence.state {
        case .warning: return MilliColors.warning
        case .arriving, .success: return MilliColors.positive
        default: return MilliColors.cyanGlow.opacity(milliPresence.state == .idle ? 0.85 : 1.0)
        }
    }

    private var ringGlowColor: Color {
        ringColor.opacity(milliPresence.state == .idle ? 0.12 : 0.58)
    }

    private var ringGlowRadius: CGFloat {
        milliPresence.state == .idle ? 1 : (milliPresence.state == .celebration ? 12 : 7)
    }

    private func updatePresenceMotion(for state: MilliPresence.State) {
        guard !reduceMotion else {
            ringRotation = 0
            counterRotation = 0
            celebrationLift = 0
            celebrationScale = 1
            return
        }

        switch state {
        case .celebration:
            ringRotation = 0
            counterRotation = 0
            withAnimation(.linear(duration: 0.72).repeatCount(6, autoreverses: false)) {
                ringRotation = 2160
            }
            withAnimation(.linear(duration: 0.92).repeatCount(5, autoreverses: false)) {
                counterRotation = -1800
            }
            withAnimation(.spring(response: 0.24, dampingFraction: 0.45).repeatCount(7, autoreverses: true)) {
                celebrationLift = -8
                celebrationScale = 1.10
            }
        case .success:
            ringRotation = 0
            withAnimation(.easeOut(duration: 0.8)) { ringRotation = 360 }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55).repeatCount(2, autoreverses: true)) {
                celebrationLift = -4
                celebrationScale = 1.05
            }
        case .thinking, .speaking, .navigating, .rerouting:
            ringRotation = 0
            withAnimation(.linear(duration: state == .rerouting ? 0.8 : 1.8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            celebrationLift = 0
            celebrationScale = 1
        case .turnLeft:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) { ringRotation = -32 }
            celebrationLift = 0
            celebrationScale = 1.02
        case .turnRight:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) { ringRotation = 32 }
            celebrationLift = 0
            celebrationScale = 1.02
        case .arriving:
            withAnimation(.spring(response: 0.36, dampingFraction: 0.55).repeatCount(3, autoreverses: true)) {
                celebrationScale = 1.07
            }
            celebrationLift = 0
        default:
            withAnimation(.easeOut(duration: 0.3)) {
                ringRotation = 0
                counterRotation = 0
                celebrationLift = 0
                celebrationScale = 1
            }
        }
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
        path.addCurve(to: CGPoint(x: crestCenter, y: deckY - crestHeight), control1: CGPoint(x: shoulderStart + crestWidth * 0.35, y: deckY), control2: CGPoint(x: shoulderStart + crestWidth * 0.35, y: deckY - crestHeight))
        path.addCurve(to: CGPoint(x: shoulderEnd, y: deckY), control1: CGPoint(x: shoulderEnd - crestWidth * 0.35, y: deckY - crestHeight), control2: CGPoint(x: shoulderEnd - crestWidth * 0.35, y: deckY))
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
            path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
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
                .environmentObject(MilliPresence())
        }
    }
}
