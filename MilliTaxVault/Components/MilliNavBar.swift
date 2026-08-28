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
        case .vault: return "wallet.fill"
        case .activity: return "safari"
        case .wealth: return "chart.bar.fill"
        case .cockpit: return "ellipsis"
        case .home: return ""
        }
    }

    // Keep internal routing terminology separate from customer-facing navigation copy.
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
// Production cockpit navigation bar reconstructed against the MILLI
// Deviation/Acceptance Spec v1 (Aug 28, 2026), sections 1 and 2:
// - Sculpted metallic bridge silhouette (NOT a rounded rectangle):
//   raised polished-chrome top rail sweeping up toward the center M housing,
//   beveled machined chamfer on the side wings.
// - Four-layer material stack: (1) polished chrome rail, (2) brushed metal
//   bridge body, (3) recessed black-glass nav cavity inset below the crest,
//   (4) carbon bottom edge with ambient drop shadow.
// - Continuous cyan under-glow beneath the bridge crest, intensifying under
//   the active tab.
// - Bar height 84 pt (compact) / 92 pt (standard, Pro Max) excluding safe area;
//   recessed cavity occupies the middle 60% of the height.
// - Center M: 72 pt (compact) / 80 pt (standard, Pro Max) segmented cyan ring
//   assembly piercing the bridge crest.

struct MilliNavBar: View {
    @Binding var selectedTab: MilliTab
    var onHomeTap: () -> Void = {}

    @State private var isDialPressed = false
    @State private var glowPulse = false
    @State private var pulseStreaks = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var barHeight: CGFloat { verticalSizeClass == .compact ? 84 : 92 }
    private var dialSize: CGFloat { verticalSizeClass == .compact ? 72 : 80 }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Ambient cyan bloom behind the whole bridge.
            Capsule(style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            MilliColors.cyanGlow.opacity(glowPulse ? 0.32 : 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 110
                    )
                )
                .frame(height: barHeight)
                .blur(radius: 20)
                .offset(y: -4)

            cockpitBarBody

            centerDialButton
                .offset(y: -barHeight * 0.28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: barHeight + 14)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                pulseStreaks = true
            }
        }
    }

    // MARK: - Cockpit Bridge Body (four-layer material stack)

    private var cockpitBarBody: some View {
        ZStack {
            // Layer 4 (bottom): carbon edge line + ambient drop shadow.
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(hex: "0E1114"))
                .shadow(color: Color.black.opacity(0.40), radius: 8, y: 4)

            // Layer 2: brushed metal bridge body — Silver over Dark Graphite,
            // directional horizontal sheen.
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "1A1D21"), location: 0.0),
                            .init(color: MilliColors.silver.opacity(0.25), location: 0.30),
                            .init(color: MilliColors.silver.opacity(0.18), location: 0.55),
                            .init(color: Color(hex: "1A1D21"), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Directional horizontal sheen.
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.10), location: 0.0),
                            .init(color: Color.white.opacity(0.02), location: 0.25),
                            .init(color: Color.white.opacity(0.09), location: 0.52),
                            .init(color: Color.white.opacity(0.01), location: 0.80),
                            .init(color: Color.white.opacity(0.06), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .blendMode(.plusLighter)
                )

            // Layer 3: recessed black-glass nav cavity — inset 6 pt below the
            // bridge crest, middle 60% of the bar height, items sit in a tray.
            HStack(spacing: 0) {
                Spacer(minLength: 14)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: "07090B"))
                    .background(.ultraThinMaterial)
                    .overlay(
                        // 2 pt inner shadow (Obsidian, 4 pt blur) so items sit in a tray.
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color(hex: "07090B").opacity(0.85), lineWidth: 2)
                            .blur(radius: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                    )
                    .frame(height: barHeight * 0.60)
                Spacer(minLength: 14)
            }

            // Layer 1 (top): polished-chrome rail crest — 2 pt white-to-silver
            // gradient stroke at 60% opacity, sweeping up toward center.
            ChromeBridgeCrestShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), MilliColors.silver.opacity(0.60)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .opacity(0.60)

            // 1 pt specular highlight line offset 2 pt below the rail crest.
            ChromeBridgeCrestShape()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                .offset(y: 2)

            // Continuous cyan under-glow line beneath the bridge crest,
            // intensifying to 40% under the active tab.
            ChromeBridgeCrestShape()
                .stroke(
                    MilliColors.cyanGlow.opacity(glowPulse ? 0.40 : 0.25),
                    lineWidth: 1.5
                )
                .blur(radius: 3)
                .offset(y: 3.5)

            HStack(spacing: 0) {
                tabButton(.vault)
                tabButton(.activity)

                Spacer()
                    .frame(width: dialSize + 16)

                tabButton(.wealth)
                tabButton(.cockpit)
            }
            .padding(.horizontal, 12)
        }
        .frame(height: barHeight)
        .shadow(color: Color.black.opacity(0.90), radius: 18, x: 0, y: 10)
    }

    // MARK: - Tab Item Button (24 pt icons, Inter 10 uppercase, 1 pt tracking)

    private func tabButton(_ tab: MilliTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedTab = tab
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isSelected {
                        // 8 pt cyan halo at 20% under the active tab.
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        MilliColors.cyanGlow.opacity(0.35),
                                        MilliColors.cyanGlow.opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 2,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 34, height: 34)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 24, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(
                            isSelected
                                ? MilliColors.cyanGlow
                                : MilliColors.silver.opacity(0.70)
                        )
                        .shadow(
                            color: isSelected ? MilliColors.cyanGlow.opacity(0.75) : .clear,
                            radius: 5
                        )
                }
                .frame(height: 26)

                Text(tab.displayName)
                    .font(.custom("Inter-Medium", size: 10))
                    .tracking(1)
                    .foregroundStyle(
                        isSelected ? Color.white : MilliColors.silver.opacity(0.60)
                    )
                    .shadow(
                        color: isSelected ? MilliColors.cyanGlow.opacity(0.40) : .clear,
                        radius: 3
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: barHeight * 0.60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.displayName.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Center M Assembly (spec section 2)

    private var centerDialButton: some View {
        Button {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.72)) {
                selectedTab = .home
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onHomeTap()
        } label: {
            ZStack {
                // 6 pt cyan ambient glow at 15% behind the assembly.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                MilliColors.cyanGlow.opacity(glowPulse ? 0.30 : 0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 4,
                            endRadius: dialSize * 0.75
                        )
                    )
                    .frame(width: dialSize + 12, height: dialSize + 12)

                // Raised polished-chrome circular housing piercing the crest:
                // 3 pt outer bevel ring.
                Circle()
                    .fill(MilliGradients.chromeRing)
                    .frame(width: dialSize, height: dialSize)
                    .shadow(color: Color.black.opacity(0.95), radius: 10, x: 0, y: 7)

                // Inner recess: black glass.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "141A22"), Color(hex: "07090B"), Color.black],
                            center: .center,
                            startRadius: 1,
                            endRadius: dialSize / 2
                        )
                    )
                    .frame(width: dialSize - 6, height: dialSize - 6)

                // Segmented cyan ring: 8 segments, 4 pt gaps, 4 pt stroke,
                // Electric Cyan -> Deep Cyan circumferential gradient.
                segmentedCyanRing

                // 0.5 pt polished silver outer edge for metallic sheen.
                Circle()
                    .stroke(MilliColors.silver.opacity(0.55), lineWidth: 0.5)
                    .frame(width: dialSize - 1, height: dialSize - 1)
                    .allowsHitTesting(false)

                // 3D beveled metallic M glyph — ~55% of ring inner diameter.
                Image("MilliMLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: dialSize * 0.55 * 0.82, height: dialSize * 0.55 * 0.82)
                    .blendMode(.screen)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.60), radius: 4)
                    .accessibilityHidden(true)

                // Top specular highlight crescent.
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: dialSize - 8, height: dialSize - 8)
                    .mask(
                        VStack(spacing: 0) {
                            Ellipse().frame(height: (dialSize - 8) * 0.34)
                            Spacer()
                        }
                    )
                    .allowsHitTesting(false)
            }
            .scaleEffect(isDialPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isDialPressed)
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

    // 8-segment cyan ring, 4 pt gaps, 4 pt stroke.
    private var segmentedCyanRing: some View {
        let segmentCount = 8
        let gapDegrees: Double = 4
        let ringRadius: CGFloat = (dialSize - 10) / 2

        return ZStack {
            ForEach(0..<segmentCount, id: \.self) { index in
                let startAngle = Double(index) / Double(segmentCount) * 360 + gapDegrees / 2
                let sweep = 360.0 / Double(segmentCount) - gapDegrees

                Circle()
                    .trim(from: startAngle / 360, to: (startAngle + sweep) / 360)
                    .stroke(
                        // Circumferential Electric Cyan -> Deep Cyan gradient.
                        AngularGradient(
                            colors: [
                                MilliColors.cyanGlow,
                                MilliColors.deepCyan,
                                Color(hex: "0077B6"),
                                MilliColors.cyanGlow.opacity(0.85)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: dialSize - 10, height: dialSize - 10)
                    .shadow(
                        color: MilliColors.cyanGlow.opacity(glowPulse ? 0.52 : 0.22),
                        radius: 2
                    )
                    .rotationEffect(
                        .degrees(reduceMotion ? 0 : (pulseStreaks ? 360.0 / Double(segmentCount) : 0))
                    )
            }
        }
        .frame(width: ringRadius * 2, height: ringRadius * 2)
    }
}

// MARK: - Chrome Bridge Crest Shape
// The sculpted top edge of the bar: a raised rail that sweeps upward toward
// center and wraps around the Center M housing — not a plain rounded rect.

struct ChromeBridgeCrestShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let crestRise: CGFloat = 12 // bridge crest rises 10-14 pt at center
        let housingHalfWidth: CGFloat = rect.width * 0.14
        let center = rect.midX
        let topY = rect.minY + 2

        // Left wing: machined chamfer rising toward center.
        path.move(to: CGPoint(x: rect.minX + 34, y: topY))
        path.addLine(to: CGPoint(x: center - housingHalfWidth, y: topY + crestRise * 0.4))

        // Wrap around the center M housing (arc over the dial).
        path.addQuadCurve(
            to: CGPoint(x: center + housingHalfWidth, y: topY + crestRise * 0.4),
            control: CGPoint(x: center, y: topY - crestRise * 0.35)
        )

        // Right wing: machined chamfer falling away from center.
        path.addLine(to: CGPoint(x: rect.maxX - 34, y: topY))

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
