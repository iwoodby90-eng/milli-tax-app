import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0

    private let slides: [OnboardingSlide] = [
        .init(
            kind: .autopilot,
            eyebrow: "MILLI AUTOPILOT™",
            headline: "Every payout,\non Autopilot.",
            body: "Protect taxes first, then direct the rest toward the financial goals you choose."
        ),
        .init(
            kind: .taxVault,
            eyebrow: "MILLI TAX VAULT™",
            headline: "Know your\ntax position.",
            body: "See your protected reserve, annual target, quarterly outlook, and readiness in one clear financial cockpit."
        ),
        .init(
            kind: .activity,
            eyebrow: "MILEAGE INTELLIGENCE",
            headline: "Track every\nbusiness mile.",
            body: "Turn driving into organized deduction records with route context, trip history, and mileage totals in one place."
        )
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                onboardingBackground

                VStack(spacing: 0) {
                    topBar
                        .padding(.top, 4)

                    TabView(selection: $currentPage) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                            OnboardingSlideView(slide: slide, availableHeight: proxy.size.height)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    controls
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                MilliWordmark(fontSize: 23, tracking: 5.1)
                Text("MONEY, MADE INTELLIGENT.")
                    .font(.custom("Inter-SemiBold", size: 7.8, relativeTo: .caption2))
                    .tracking(1.75)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            if currentPage < slides.count - 1 {
                Button("SKIP", action: onComplete)
                    .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption))
                    .tracking(1.0)
                    .foregroundStyle(MilliColors.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.035))
                            .overlay {
                                Capsule(style: .continuous)
                                    .stroke(Color.white.opacity(0.09), lineWidth: 0.7)
                            }
                    )
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
    }

    private var controls: some View {
        VStack(spacing: 15) {
            HStack(spacing: 7) {
                ForEach(slides.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(
                            index == currentPage
                            ? LinearGradient(
                                colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: index == currentPage ? 31 : 8, height: 5)
                        .shadow(color: index == currentPage ? MilliColors.cyanGlow.opacity(0.42) : .clear, radius: 4)
                        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: currentPage)
                }
            }

            Button(action: advance) {
                HStack(spacing: 9) {
                    Text(currentPage == slides.count - 1 ? "GET STARTED" : "CONTINUE")
                        .font(.custom("Sora-Bold", size: 15, relativeTo: .headline))
                        .tracking(0.75)
                    Spacer()
                    Image(systemName: currentPage == slides.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(Color(hex: "031013"))
                .padding(.horizontal, 19)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "84F8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.68), lineWidth: 0.8)
                        }
                        .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 12, y: 4)
                )
            }
            .buttonStyle(.plain)

            Text("Swipe to explore • settings remain editable later")
                .font(.custom("Inter-Regular", size: 10.5, relativeTo: .caption))
                .foregroundStyle(MilliColors.textTertiary)
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: "071116"), Color(hex: "05090C"), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.12), Color.clear],
                center: UnitPoint(x: 0.17, y: 0.18),
                startRadius: 8,
                endRadius: 310
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.025), Color.clear],
                center: UnitPoint(x: 0.82, y: 0.50),
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()
        }
    }

    private func advance() {
        if currentPage == slides.count - 1 {
            onComplete()
        } else {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                currentPage += 1
            }
        }
    }
}

private struct OnboardingSlide {
    enum Kind {
        case autopilot
        case taxVault
        case activity
    }

    let kind: Kind
    let eyebrow: String
    let headline: String
    let body: String
}

private struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let availableHeight: CGFloat

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                productVisual
                    .frame(maxWidth: .infinity)
                    .frame(height: min(330, max(276, availableHeight * 0.38)))
                    .padding(.top, 12)

                VStack(spacing: 12) {
                    Text(slide.eyebrow)
                        .font(.custom("Sora-SemiBold", size: 11, relativeTo: .subheadline))
                        .tracking(2.0)
                        .foregroundStyle(MilliColors.cyanGlow)

                    Text(slide.headline)
                        .font(.custom("Sora-Bold", size: 36, relativeTo: .largeTitle))
                        .foregroundStyle(MilliColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(-1.5)
                        .minimumScaleFactor(0.82)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(slide.body)
                        .font(.custom("Inter-Regular", size: 15, relativeTo: .body))
                        .foregroundStyle(MilliColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3.3)
                        .padding(.horizontal, 7)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 20)
                .padding(.bottom, 22)
            }
            .padding(.horizontal, 18)
        }
    }

    @ViewBuilder
    private var productVisual: some View {
        switch slide.kind {
        case .autopilot:
            AutopilotOnboardingVisual()
        case .taxVault:
            TaxVaultOnboardingVisual()
        case .activity:
            MileageOnboardingVisual()
        }
    }
}

// MARK: - Shared premium instrument surface

private struct OnboardingInstrumentSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "121C22"), Color(hex: "080E12"), Color.black],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.28), MilliColors.cyanGlow.opacity(0.20), Color.white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    }
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 120, height: 1)
                            .padding(.top, 1)
                    }
                    .shadow(color: .black.opacity(0.60), radius: 20, y: 10)
                    .shadow(color: MilliColors.cyanGlow.opacity(0.06), radius: 18)
            )
    }
}

// MARK: - Autopilot visual

private struct AutopilotOnboardingVisual: View {
    var body: some View {
        OnboardingInstrumentSurface {
            VStack(spacing: 15) {
                instrumentHeader(
                    title: "AUTOPILOT READY",
                    subtitle: "PAYOUT ROUTING",
                    icon: "bolt.shield.fill",
                    color: MilliColors.positive
                )

                HStack(spacing: 14) {
                    autopilotDial

                    VStack(alignment: .leading, spacing: 8) {
                        allocationRow("Taxes", "$46.86", "25%", MilliColors.cyanGlow)
                        allocationRow("Retirement", "$9.37", "5%", MilliColors.positive)
                        allocationRow("Savings", "$5.62", "3%", MilliColors.deepCyan)
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AVAILABLE AFTER ALLOCATIONS")
                            .font(.custom("Inter-SemiBold", size: 8.5))
                            .tracking(0.8)
                            .foregroundStyle(MilliColors.textTertiary)
                        Text("$125.57")
                            .font(.custom("Sora-Bold", size: 25))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.36), radius: 5)
                }
                .padding(.horizontal, 13)
                .frame(height: 62)
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.028)))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.09), lineWidth: 0.7))
            }
        }
    }

    private var autopilotDial: some View {
        ZStack {
            Circle()
                .fill(
                    AngularGradient(
                        colors: [Color(hex: "F2F4F6"), Color(hex: "747B84"), Color(hex: "E1E5E9"), Color(hex: "454C54"), Color(hex: "EFF2F4")],
                        center: .center
                    )
                )
                .frame(width: 128, height: 128)
                .shadow(color: .black.opacity(0.72), radius: 8, y: 5)

            Circle()
                .fill(Color(hex: "05090C"))
                .frame(width: 116, height: 116)

            SegmentedArcRing(segments: 6, gapDegrees: 12)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "8AF8FF"), MilliColors.cyanGlow, MilliColors.deepCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .butt)
                )
                .frame(width: 99, height: 99)
                .shadow(color: MilliColors.cyanGlow.opacity(0.44), radius: 6)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "172128"), Color(hex: "070A0D"), Color.black],
                        center: UnitPoint(x: 0.42, y: 0.30),
                        startRadius: 1,
                        endRadius: 42
                    )
                )
                .frame(width: 82, height: 82)
                .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 0.8))

            MilliMMark(size: 53)
                .shadow(color: MilliColors.cyanGlow.opacity(0.48), radius: 7)
        }
    }

    private func allocationRow(_ title: String, _ value: String, _ percent: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.40), radius: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 11.5))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(percent)
                    .font(.custom("Inter-Regular", size: 9))
                    .foregroundStyle(MilliColors.textTertiary)
            }
            Spacer(minLength: 3)
            Text(value)
                .font(.custom("Sora-SemiBold", size: 11.5))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .frame(height: 42)
        .background(RoundedRectangle(cornerRadius: 11).fill(Color.white.opacity(0.023)))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(color.opacity(0.16), lineWidth: 0.7))
    }
}

// MARK: - Tax Vault visual

private struct TaxVaultOnboardingVisual: View {
    var body: some View {
        OnboardingInstrumentSurface {
            VStack(spacing: 13) {
                instrumentHeader(
                    title: "TAXES PROTECTED",
                    subtitle: "MILLI TAX VAULT™",
                    icon: "lock.shield.fill",
                    color: MilliColors.cyanGlow
                )

                HStack(spacing: 16) {
                    reserveRing

                    VStack(alignment: .leading, spacing: 10) {
                        vaultMetric("ANNUAL TARGET", "$22,974", MilliColors.textPrimary)
                        vaultMetric("READY SCORE", "85 / 100", MilliColors.positive)
                        vaultMetric("NEXT QUARTER", "$1,247", MilliColors.cyanGlow)
                    }
                    .frame(maxWidth: .infinity)
                }

                HStack(spacing: 8) {
                    statusPill("FEDERAL", "PROTECTED")
                    statusPill("STATE", "PROTECTED")
                    statusPill("SE TAX", "TRACKED")
                }
            }
        }
    }

    private var reserveRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 13)
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    AngularGradient(
                        colors: [MilliColors.deepCyan, MilliColors.cyanGlow, Color(hex: "8AF8FF"), MilliColors.positive],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 8)

            VStack(spacing: 2) {
                Text("$5,284")
                    .font(.custom("Sora-Bold", size: 23, relativeTo: .title))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                Text("RESERVED")
                    .font(.custom("Inter-SemiBold", size: 8.5))
                    .tracking(0.8)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .frame(width: 150, height: 150)
    }

    private func vaultMetric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom("Inter-SemiBold", size: 8.3))
                .tracking(0.65)
                .foregroundStyle(MilliColors.textTertiary)
            Text(value)
                .font(.custom("Sora-SemiBold", size: 14))
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    private func statusPill(_ title: String, _ status: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.custom("Inter-SemiBold", size: 7.7))
                .foregroundStyle(MilliColors.textTertiary)
            Text(status)
                .font(.custom("Inter-SemiBold", size: 8.5))
                .foregroundStyle(MilliColors.positive)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(RoundedRectangle(cornerRadius: 10).fill(MilliColors.positive.opacity(0.045)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(MilliColors.positive.opacity(0.16), lineWidth: 0.7))
    }
}

// MARK: - Mileage visual

private struct MileageOnboardingVisual: View {
    var body: some View {
        OnboardingInstrumentSurface {
            ZStack {
                mapField

                VStack {
                    instrumentHeader(
                        title: "TRACKING ACTIVE",
                        subtitle: "LIVE BUSINESS TRIP",
                        icon: "location.fill",
                        color: MilliColors.positive
                    )

                    Spacer()

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("18.64 mi")
                                .font(.custom("Sora-Bold", size: 30, relativeTo: .title))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.textPrimary)
                            Text("CURRENT TRIP")
                                .font(.custom("Inter-SemiBold", size: 8.5))
                                .tracking(0.9)
                                .foregroundStyle(MilliColors.textTertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("$9.82")
                                .font(.custom("Sora-Bold", size: 23))
                                .monospacedDigit()
                                .foregroundStyle(MilliColors.cyanGlow)
                            Text("EST. DEDUCTION")
                                .font(.custom("Inter-SemiBold", size: 8.5))
                                .tracking(0.7)
                                .foregroundStyle(MilliColors.textTertiary)
                        }
                    }
                    .padding(13)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.black.opacity(0.50))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 0.7)
                            }
                    )
                }
            }
        }
    }

    private var mapField: some View {
        Canvas { context, size in
            for index in 0..<9 {
                var street = Path()
                let y = size.height * (0.07 + CGFloat(index) * 0.105)
                street.move(to: CGPoint(x: -20, y: y))
                street.addCurve(
                    to: CGPoint(x: size.width + 20, y: y - 18),
                    control1: CGPoint(x: size.width * 0.28, y: y - 20),
                    control2: CGPoint(x: size.width * 0.68, y: y + 15)
                )
                context.stroke(street, with: .color(Color.white.opacity(0.045)), lineWidth: 0.8)
            }

            for index in 0..<5 {
                var crossStreet = Path()
                let x = size.width * (0.10 + CGFloat(index) * 0.21)
                crossStreet.move(to: CGPoint(x: x, y: -10))
                crossStreet.addCurve(
                    to: CGPoint(x: x + 20, y: size.height + 10),
                    control1: CGPoint(x: x - 18, y: size.height * 0.33),
                    control2: CGPoint(x: x + 17, y: size.height * 0.70)
                )
                context.stroke(crossStreet, with: .color(Color.white.opacity(0.035)), lineWidth: 0.7)
            }

            var route = Path()
            route.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.73))
            route.addLine(to: CGPoint(x: size.width * 0.27, y: size.height * 0.58))
            route.addLine(to: CGPoint(x: size.width * 0.43, y: size.height * 0.63))
            route.addCurve(
                to: CGPoint(x: size.width * 0.63, y: size.height * 0.37),
                control1: CGPoint(x: size.width * 0.54, y: size.height * 0.61),
                control2: CGPoint(x: size.width * 0.53, y: size.height * 0.42)
            )
            route.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.23))
            context.stroke(
                route,
                with: .color(MilliColors.cyanGlow),
                style: StrokeStyle(lineWidth: 4.2, lineCap: .round, lineJoin: .round)
            )
        }
        .padding(.top, 36)
        .padding(.bottom, 72)
        .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 6)
    }
}

// MARK: - Shared visual header

private func instrumentHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
    HStack(spacing: 9) {
        ZStack {
            Circle()
                .fill(color.opacity(0.10))
                .frame(width: 31, height: 31)
                .overlay {
                    Circle().stroke(color.opacity(0.24), lineWidth: 0.7)
                }
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
        }

        VStack(alignment: .leading, spacing: 1) {
            Text(title)
                .font(.custom("Inter-SemiBold", size: 10.5))
                .tracking(0.7)
                .foregroundStyle(color)
            Text(subtitle)
                .font(.custom("Inter-Medium", size: 8.2))
                .tracking(0.5)
                .foregroundStyle(MilliColors.textTertiary)
        }

        Spacer()

        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text("LIVE")
                .font(.custom("Inter-SemiBold", size: 8))
                .foregroundStyle(color)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}
