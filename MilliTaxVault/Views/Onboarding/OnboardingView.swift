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
            body: "See the reserve, annual target, quarterly outlook, and audit trail without rebuilding the math yourself."
        ),
        .init(
            kind: .activity,
            eyebrow: "MILEAGE INTELLIGENCE",
            headline: "Track every\nbusiness mile.",
            body: "Turn driving into organized deduction records with route context, trip history, and mileage totals in one place."
        )
    ]

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                topBar

                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        OnboardingSlideView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        ZStack {
            MilliWordmark(fontSize: 19, tracking: 4.3)

            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(MilliColors.cyanGlow)
                        .frame(width: 5, height: 5)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.55), radius: 4)
                    Text("MONEY, MADE INTELLIGENT.")
                        .font(.custom("Inter-SemiBold", size: 8, relativeTo: .caption2))
                        .tracking(0.6)
                        .foregroundStyle(MilliColors.textTertiary)
                }

                Spacer()

                if currentPage < slides.count - 1 {
                    Button("Skip", action: onComplete)
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .frame(height: 48)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                ForEach(slides.indices, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index == currentPage ? MilliColors.cyanGlow : Color.white.opacity(0.13))
                        .frame(width: index == currentPage ? 24 : 6, height: 5)
                        .shadow(color: index == currentPage ? MilliColors.cyanGlow.opacity(0.35) : .clear, radius: 4)
                        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: currentPage)
                }
            }

            Button(action: advance) {
                HStack(spacing: 8) {
                    Text(currentPage == slides.count - 1 ? "GET STARTED" : "CONTINUE")
                        .font(.custom("Sora-SemiBold", size: 14, relativeTo: .headline))
                        .tracking(0.8)
                    Image(systemName: currentPage == slides.count - 1 ? "checkmark" : "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(MilliColors.blackGlass)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyanGlow, Color(hex: "0CB9D7")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 10)
                )
            }
            .buttonStyle(.plain)

            Text("Swipe to explore • you can change these settings later")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textTertiary)
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.075), Color.clear],
                center: UnitPoint(x: 0.5, y: 0.22),
                startRadius: 8,
                endRadius: 270
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [Color.white.opacity(0.016), Color.clear, Color.black.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
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

    var body: some View {
        VStack(spacing: 0) {
            productVisual
                .frame(height: 292)
                .padding(.top, 10)

            VStack(spacing: 12) {
                Text(slide.eyebrow)
                    .font(MilliFont.sectionLabel)
                    .tracking(1.25)
                    .foregroundStyle(MilliColors.cyanGlow)

                Text(slide.headline)
                    .font(.custom("Sora-Bold", size: 34, relativeTo: .largeTitle))
                    .foregroundStyle(MilliColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-1)
                    .minimumScaleFactor(0.84)

                Text(slide.body)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 18)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 18)

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 22)
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

// MARK: - Native product illustrations

private struct AutopilotOnboardingVisual: View {
    var body: some View {
        ZStack {
            instrumentBackdrop

            VStack(spacing: 13) {
                HStack(spacing: 7) {
                    Circle().fill(MilliColors.positive).frame(width: 6, height: 6)
                    Text("AUTOPILOT READY")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.8)
                        .foregroundStyle(MilliColors.positive)
                }

                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.80))
                        .frame(width: 122, height: 122)
                        .overlay {
                            Circle()
                                .stroke(
                                    AngularGradient(
                                        colors: [MilliColors.chromeDark, MilliColors.chromeWhite, MilliColors.chromeMid, MilliColors.chromeWhite, MilliColors.chromeDark],
                                        center: .center
                                    ),
                                    lineWidth: 5
                                )
                        }

                    Circle()
                        .stroke(MilliColors.cyanGlow.opacity(0.70), style: StrokeStyle(lineWidth: 2, dash: [3, 4]))
                        .frame(width: 102, height: 102)
                        .shadow(color: MilliColors.cyanGlow.opacity(0.40), radius: 7)

                    Image("MilliMLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 66, height: 66)
                        .blendMode(.screen)
                }

                HStack(spacing: 7) {
                    allocationChip("Taxes", "23%", icon: "lock.shield.fill", color: MilliColors.cyanGlow)
                    allocationChip("Retire", "5%", icon: "building.columns.fill", color: MilliColors.positive)
                    allocationChip("Save", "3%", icon: "target", color: MilliColors.deepCyan)
                }
            }
        }
    }

    private var instrumentBackdrop: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "111A21"), Color(hex: "060A0D")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(MilliColors.cyanGlow.opacity(0.13), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.55), radius: 18, y: 9)
    }

    private func allocationChip(_ title: String, _ value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(MilliFont.numericSmall)
                .foregroundStyle(MilliColors.textPrimary)
            Text(title)
                .font(.custom("Inter-Regular", size: 8.5, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textTertiary)
        }
        .frame(width: 62, height: 54)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.14), lineWidth: 0.7)
                }
        )
    }
}

private struct TaxVaultOnboardingVisual: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "0E1820"), Color(hex: "050A0D")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.14), lineWidth: 0.8)
                }

            VStack(spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("TAXES PROTECTED")
                        .font(MilliFont.sectionLabel)
                        .tracking(0.85)
                        .foregroundStyle(MilliColors.cyanGlow)
                }

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: 0.72)
                        .stroke(
                            AngularGradient(
                                colors: [MilliColors.deepCyan, MilliColors.cyanGlow, MilliColors.positive],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: MilliColors.cyanGlow.opacity(0.22), radius: 8)

                    VStack(spacing: 2) {
                        Text("$5,284")
                            .font(.custom("Sora-Bold", size: 24, relativeTo: .title))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("RESERVED")
                            .font(MilliFont.sectionLabel)
                            .tracking(0.7)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                }
                .frame(width: 150, height: 150)

                HStack(spacing: 18) {
                    vaultMetric("23%", "reserve rate")
                    vaultMetric("85", "ready score")
                    vaultMetric("Q3", "next payment")
                }
            }
        }
        .shadow(color: .black.opacity(0.52), radius: 18, y: 9)
    }

    private func vaultMetric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(MilliFont.numericSmall)
                .foregroundStyle(MilliColors.textPrimary)
            Text(label)
                .font(.custom("Inter-Regular", size: 8.5, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textTertiary)
        }
    }
}

private struct MileageOnboardingVisual: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "08151D"), Color(hex: "050B0F")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.14), lineWidth: 0.8)
                }

            Canvas { context, size in
                for index in 0..<8 {
                    var street = Path()
                    let y = size.height * (0.12 + CGFloat(index) * 0.11)
                    street.move(to: CGPoint(x: -10, y: y))
                    street.addCurve(
                        to: CGPoint(x: size.width + 10, y: y - 20),
                        control1: CGPoint(x: size.width * 0.28, y: y - 16),
                        control2: CGPoint(x: size.width * 0.65, y: y + 13)
                    )
                    context.stroke(street, with: .color(Color(hex: "173044").opacity(0.55)), lineWidth: 0.7)
                }

                var route = Path()
                route.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.72))
                route.addLine(to: CGPoint(x: size.width * 0.27, y: size.height * 0.58))
                route.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.63))
                route.addCurve(
                    to: CGPoint(x: size.width * 0.62, y: size.height * 0.38),
                    control1: CGPoint(x: size.width * 0.54, y: size.height * 0.62),
                    control2: CGPoint(x: size.width * 0.52, y: size.height * 0.42)
                )
                route.addLine(to: CGPoint(x: size.width * 0.83, y: size.height * 0.24))
                context.stroke(route, with: .color(MilliColors.cyanGlow), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            }
            .padding(8)

            VStack {
                HStack {
                    HStack(spacing: 5) {
                        Circle().fill(MilliColors.positive).frame(width: 6, height: 6)
                        Text("TRACKING ACTIVE")
                            .font(MilliFont.sectionLabel)
                            .tracking(0.7)
                            .foregroundStyle(MilliColors.positive)
                    }
                    Spacer()
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(MilliColors.cyanGlow)
                }

                Spacer()

                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("18.64 mi")
                            .font(.custom("Sora-Bold", size: 27, relativeTo: .title))
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.textPrimary)
                        Text("CURRENT TRIP")
                            .font(MilliFont.sectionLabel)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$9.82")
                            .font(MilliFont.numericMedium)
                            .monospacedDigit()
                            .foregroundStyle(MilliColors.cyanGlow)
                        Text("EST. DEDUCTION")
                            .font(MilliFont.sectionLabel)
                            .foregroundStyle(MilliColors.textTertiary)
                    }
                }
            }
            .padding(16)
        }
        .shadow(color: .black.opacity(0.52), radius: 18, y: 9)
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .preferredColorScheme(.dark)
}
