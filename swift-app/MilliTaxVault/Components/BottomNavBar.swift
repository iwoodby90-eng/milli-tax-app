import SwiftUI

// MARK: - Bel Air Cockpit Navigation Bar
// Inspired by 1954 Chevrolet Bel Air dashboard: brushed titanium finish,
// specular chrome edges, circular gauge motifs, and a 3D hardware "M" dial center button.

struct BottomNavBar: View {
    @Binding var selection: MilliTab
    var onCenterTap: () -> Void

    // Haptic feedback for tactile hardware feel
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        HStack(spacing: 0) {
            navGauge(.vault)
            navGauge(.wealth)
            centerMDial
            navGauge(.activity)
            navGauge(.cockpit)
        }
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .background(navBarBackground)
        .padding(.horizontal, 10)
    }

    // MARK: - Nav Bar Background (Brushed Titanium)

    private var navBarBackground: some View {
        ZStack {
            // Base: dark brushed metal
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "1C1C26"),
                            Color(hex: "16161E"),
                            Color(hex: "1C1C26")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Specular top edge highlight (chrome bezel)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            // Subtle inner shadow for depth
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
                .padding(1)
        }
        .shadow(color: Color.black.opacity(0.6), radius: 12, y: 6)
    }

    // MARK: - Nav Gauge Button (circular instrument motif)

    private func navGauge(_ tab: MilliTab) -> some View {
        let isActive = selection == tab

        return Button {
            impactFeedback.impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    // Gauge ring
                    Circle()
                        .stroke(
                            isActive ? MilliPalette.accent.opacity(0.4) : Color.white.opacity(0.06),
                            lineWidth: 1.5
                        )
                        .frame(width: 36, height: 36)

                    // Gauge fill glow
                    if isActive {
                        Circle()
                            .fill(MilliPalette.accent.opacity(0.08))
                            .frame(width: 34, height: 34)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isActive ? MilliPalette.accent : MilliPalette.textSecondary)
                }

                Text(tab.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isActive ? MilliPalette.accent : MilliPalette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Center M Dial (3D Chrome Hardware)

    private var centerMDial: some View {
        Button {
            impactFeedback.impactOccurred()
            onCenterTap()
        } label: {
            ZStack {
                // Outer chrome bezel — angular gradient for metallic sheen
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                MilliPalette.chrome1,
                                MilliPalette.chrome3,
                                MilliPalette.chrome1,
                                MilliPalette.chrome2,
                                MilliPalette.chrome1,
                                MilliPalette.chrome3,
                                MilliPalette.chrome1
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 62, height: 62)
                    .shadow(color: Color.black.opacity(0.6), radius: 6, y: 3)
                    .shadow(color: MilliPalette.accent.opacity(0.15), radius: 12, y: 0)

                // Inner dark face (like a gauge face)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "1E1E2E"), MilliPalette.background],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)

                // Inner chrome ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [MilliPalette.chrome1, MilliPalette.chrome3],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 48, height: 48)

                // The M letterform — chrome gradient with cyan runway
                Text("M")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MilliPalette.chrome1, MilliPalette.accent, MilliPalette.chrome1],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: MilliPalette.accent.opacity(0.6), radius: 4, y: 0)

                // Tiny indicator dot at 12 o'clock (like a gauge marker)
                Circle()
                    .fill(MilliPalette.accent)
                    .frame(width: 4, height: 4)
                    .offset(y: -20)
                    .shadow(color: MilliPalette.accent, radius: 2)
            }
        }
        .offset(y: -14)
        .frame(maxWidth: .infinity)
    }
}
