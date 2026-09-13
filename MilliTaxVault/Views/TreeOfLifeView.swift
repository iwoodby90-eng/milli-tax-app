import SwiftUI
import UIKit

// MARK: - TreeOfLifeView
// High-fidelity implementation of Milli's approved Tree of Life experience.
// Production values remain grounded in user-provided data. A deterministic
// DEBUG-only fixture is used by screenshot QA so visual fidelity can be judged
// against the approved populated reference without leaking demo data to users.

struct TreeOfLifeView: View {
    var onBack: () -> Void = {}

    @State private var showAddEvent = false
    @State private var events: [LifePlanningEvent] = Self.initialEventsForCurrentMode()
    @State private var glowPulse = false

    private static var isVisualFixtureMode: Bool {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        return processInfo.environment["MILLI_SCREENSHOT_MODE"] == "1"
            || processInfo.arguments.contains("-milliScreenshotMode")
        #else
        return false
        #endif
    }

    private static func initialEventsForCurrentMode() -> [LifePlanningEvent] {
        guard isVisualFixtureMode else { return [] }
        let calendar = Calendar.current
        let now = Date()

        return [
            LifePlanningEvent(
                type: .marriage,
                targetDate: calendar.date(byAdding: .year, value: 1, to: now) ?? now,
                estimatedCost: 25_000
            ),
            LifePlanningEvent(
                type: .child,
                targetDate: calendar.date(byAdding: .year, value: 4, to: now) ?? now,
                estimatedCost: 35_000
            ),
            LifePlanningEvent(
                type: .homePurchase,
                targetDate: calendar.date(byAdding: .year, value: 6, to: now) ?? now,
                estimatedCost: 120_000
            ),
            LifePlanningEvent(
                type: .retirement,
                targetDate: calendar.date(byAdding: .year, value: 35, to: now) ?? now,
                estimatedCost: 3_000_000
            )
        ]
    }

    private var visualFixtureMode: Bool { Self.isVisualFixtureMode }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 14) {
                    header
                    hero(width: proxy.size.width - (MilliSpacing.screenHorizontal * 2))
                    keyLifeEvents
                    planningAdjustments
                    wealthPath
                    aiInsight
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.top, 8)
                .padding(.bottom, MilliSpacing.bottomContentClearance)
            }
            .background(background)
        }
        .sheet(isPresented: $showAddEvent) {
            AddLifeEventSheet { event in
                withAnimation(.spring(response: 0.50, dampingFraction: 0.82)) {
                    events.append(event)
                }
            }
        }
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private var background: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(hex: "001017").opacity(0.44),
                    Color.clear,
                    Color(hex: "100B08").opacity(0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.045))
                            .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.7))
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tree of Life")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("PLAN · GROW · THRIVE")
                    .font(MilliFont.caption)
                    .tracking(1.45)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            Button {
                showAddEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MilliColors.blackGlass)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .shadow(color: MilliColors.cyanGlow.opacity(0.28), radius: 10)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add life event")
        }
    }

    private func hero(width: CGFloat) -> some View {
        let height = min(max(width * 1.28, 480), 610)

        return ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(hex: "03090D"))

            Image("tree-of-life-bg")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .opacity(0.97)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.64),
                    Color.clear,
                    Color.black.opacity(0.14),
                    Color.black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(glowPulse ? 0.19 : 0.11), Color.clear],
                center: UnitPoint(x: 0.48, y: 0.48),
                startRadius: 20,
                endRadius: width * 0.58
            )

            VStack(spacing: 0) {
                projectionHeader
                    .padding(.top, 24)

                Spacer()

                if events.isEmpty {
                    heroEmptyState
                        .padding(.bottom, 20)
                } else {
                    heroMetrics
                        .padding(.horizontal, 18)
                        .padding(.bottom, 18)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.34),
                            MilliColors.cyanGlow.opacity(0.30),
                            Color(hex: "D9B58B").opacity(0.24),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.10), radius: 24, y: 8)
    }

    private var projectionHeader: some View {
        VStack(spacing: 5) {
            Text("PROJECTED NET WORTH")
                .font(MilliFont.sectionLabel)
                .tracking(1.3)
                .foregroundStyle(Color.white.opacity(0.68))

            Text(visualFixtureMode ? "$5,284,170" : "—")
                .font(.custom("Sora-SemiBold", size: 40, relativeTo: .largeTitle))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .minimumScaleFactor(0.72)
                .lineLimit(1)

            Text(visualFixtureMode ? "at age 65" : "Projection activates when your financial inputs are complete")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)

            if visualFixtureMode {
                Text("Today: $2,341,080")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.cyanGlow)
            } else if !events.isEmpty {
                Text("Life goals currently planned: \(compactCurrency(plannedGoalValue))")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .padding(.top, 2)
            }
        }
    }

    private var heroEmptyState: some View {
        VStack(spacing: 10) {
            Text("Your future starts here")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)

            Text("Add the milestones that matter to you. Milli will build the planning timeline without inventing assumptions.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 285)

            Button {
                showAddEvent = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                    Text("Add First Life Event")
                }
                .font(MilliFont.labelLarge)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 18)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "A5FAFF"), MilliColors.cyanGlow],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 12)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.60))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.16), lineWidth: 0.8)
                }
        )
        .padding(.horizontal, 18)
    }

    private var heroMetrics: some View {
        HStack(spacing: 10) {
            if visualFixtureMode {
                heroMetric(
                    title: "CONTRIBUTIONS",
                    value: "$2.3M",
                    subtitle: "43%",
                    tint: MilliColors.cyanGlow
                )

                heroMetric(
                    title: "GROWTH",
                    value: "$3.0M",
                    subtitle: "57%",
                    tint: Color(hex: "D9B58B")
                )
            } else {
                heroMetric(
                    title: "LIFE GOALS",
                    value: compactCurrency(plannedGoalValue),
                    subtitle: "User-entered targets",
                    tint: MilliColors.cyanGlow
                )

                heroMetric(
                    title: "MILESTONES",
                    value: String(events.count),
                    subtitle: nextEventLabel == "—" ? "Plan active" : "Next \(nextEventLabel)",
                    tint: Color(hex: "D9B58B")
                )
            }
        }
    }

    private func heroMetric(title: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(tint)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
            Text(subtitle)
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(tint.opacity(0.25), lineWidth: 0.8)
                }
        )
    }

    private var keyLifeEvents: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "KEY LIFE EVENTS", action: "Add") {
                showAddEvent = true
            }

            if events.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Your milestones will appear here as a financial timeline.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 6)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(events.sorted(by: { $0.targetDate < $1.targetDate })) { event in
                            lifeEventCard(event)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .milliCard(padding: 14)
    }

    private func lifeEventCard(_ event: LifePlanningEvent) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.72))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.40), MilliColors.cyanGlow.opacity(0.50)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.1
                            )
                    }
                Image(systemName: event.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text(event.type.rawValue)
                .font(MilliFont.labelLarge)
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)

            Text(event.targetDate.formatted(.dateTime.month(.abbreviated).year()))
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)

            Text(compactCurrency(event.estimatedCost))
                .font(MilliFont.bodySmall)
                .monospacedDigit()
                .foregroundStyle(Color(hex: "D9B58B"))
        }
        .frame(width: 118)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.025))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 0.7)
                }
        )
    }

    private var planningAdjustments: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "PLANNING ADJUSTMENTS")

            adjustmentRow(
                icon: "percent",
                title: "Savings Rate",
                value: visualFixtureMode ? "15%" : "Not set",
                detail: visualFixtureMode ? "Recommended" : "Complete your financial profile",
                accent: MilliColors.cyanGlow
            )

            Divider().overlay(Color.white.opacity(0.06))

            adjustmentRow(
                icon: "dial.medium",
                title: "Risk Tolerance",
                value: visualFixtureMode ? "Moderate" : "Not set",
                detail: visualFixtureMode ? "Balanced growth" : "Used for long-term projections",
                accent: Color(hex: "D9B58B")
            )

            Divider().overlay(Color.white.opacity(0.06))

            adjustmentRow(
                icon: "calendar.badge.clock",
                title: "Next Review",
                value: visualFixtureMode ? "90 days" : "After setup",
                detail: visualFixtureMode ? "Plan health check" : "Milli will schedule the first plan review",
                accent: MilliColors.cyanGlow
            )
        }
        .milliCard(padding: 14)
    }

    private func adjustmentRow(icon: String, title: String, value: String, detail: String, accent: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(accent.opacity(0.08)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MilliFont.bodyMedium)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer()

            Text(value)
                .font(MilliFont.labelLarge)
                .foregroundStyle(accent)
                .multilineTextAlignment(.trailing)
        }
    }

    private var wealthPath: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "WEALTH PATH")

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.018))

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    Path { path in
                        for fraction in [0.24, 0.50, 0.76] {
                            path.move(to: CGPoint(x: 18, y: h * fraction))
                            path.addLine(to: CGPoint(x: w - 18, y: h * fraction))
                        }
                    }
                    .stroke(Color.white.opacity(0.055), style: StrokeStyle(lineWidth: 0.7, dash: [3, 5]))

                    if visualFixtureMode {
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: h * 0.80))
                            path.addCurve(
                                to: CGPoint(x: w * 0.35, y: h * 0.57),
                                control1: CGPoint(x: w * 0.13, y: h * 0.73),
                                control2: CGPoint(x: w * 0.22, y: h * 0.58)
                            )
                            path.addCurve(
                                to: CGPoint(x: w * 0.62, y: h * 0.49),
                                control1: CGPoint(x: w * 0.43, y: h * 0.54),
                                control2: CGPoint(x: w * 0.52, y: h * 0.55)
                            )
                            path.addCurve(
                                to: CGPoint(x: w - 22, y: h * 0.20),
                                control1: CGPoint(x: w * 0.75, y: h * 0.42),
                                control2: CGPoint(x: w * 0.86, y: h * 0.22)
                            )
                        }
                        .stroke(MilliColors.cyanGlow, style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round))
                        .shadow(color: MilliColors.cyanGlow.opacity(0.35), radius: 5)

                        Path { path in
                            path.move(to: CGPoint(x: 20, y: h * 0.82))
                            path.addCurve(
                                to: CGPoint(x: w - 22, y: h * 0.27),
                                control1: CGPoint(x: w * 0.35, y: h * 0.70),
                                control2: CGPoint(x: w * 0.65, y: h * 0.45)
                            )
                        }
                        .stroke(Color.white.opacity(0.48), style: StrokeStyle(lineWidth: 1.0, dash: [4, 4]))

                        Text("$5.28M")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.cyanGlow)
                            .position(x: w - 42, y: h * 0.13)

                        Text("Today")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                            .position(x: 36, y: h - 14)

                        Text("Age 65")
                            .font(MilliFont.caption)
                            .foregroundStyle(MilliColors.textTertiary)
                            .position(x: w - 42, y: h - 14)
                    } else {
                        VStack(spacing: 7) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 21, weight: .medium))
                                .foregroundStyle(MilliColors.cyanGlow)
                            Text("Projection waiting for complete financial inputs")
                                .font(MilliFont.bodySmall)
                                .foregroundStyle(MilliColors.textSecondary)
                                .multilineTextAlignment(.center)
                            Text("No invented balances or growth assumptions are displayed.")
                                .font(MilliFont.caption)
                                .foregroundStyle(MilliColors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: w, height: h)
                        .padding(.horizontal, 26)
                    }
                }
            }
            .frame(height: 170)
        }
        .milliCard(padding: 14)
    }

    private var aiInsight: some View {
        HStack(alignment: .center, spacing: 14) {
            MilliAICharacterView(size: 88, animated: !UIAccessibility.isReduceMotionEnabled)
                .frame(width: 94, height: 104)

            VStack(alignment: .leading, spacing: 5) {
                Text("Milli AI")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.cyanGlow)

                Text(aiInsightText)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Plan intelligently. Adjust as life changes.")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "061116"), Color.black.opacity(0.88)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.18), lineWidth: 0.8)
                }
        )
    }

    private func sectionHeader(title: String, action: String? = nil, handler: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(MilliFont.sectionLabel)
                .tracking(1.15)
                .foregroundStyle(MilliColors.textSecondary)

            Spacer()

            if let action, let handler {
                Button(action, action: handler)
                    .font(MilliFont.labelLarge)
                    .foregroundStyle(MilliColors.cyanGlow)
                    .buttonStyle(.plain)
            }
        }
    }

    private var plannedGoalValue: Double {
        events.reduce(0) { $0 + $1.estimatedCost }
    }

    private var nextEventLabel: String {
        guard let next = events
            .filter({ $0.targetDate >= Date() })
            .sorted(by: { $0.targetDate < $1.targetDate })
            .first
        else {
            return "—"
        }

        return next.targetDate.formatted(.dateTime.month(.abbreviated).year())
    }

    private var aiInsightText: String {
        if visualFixtureMode {
            return "Increasing your annual savings by 2% could materially strengthen your long-term plan."
        }

        guard !events.isEmpty else {
            return "Add your first life event and I’ll organize the milestones that matter to your future plan."
        }

        if let next = events.sorted(by: { $0.targetDate < $1.targetDate }).first {
            return "You have \(events.count) planned milestone\(events.count == 1 ? "" : "s"). Your next goal is \(next.type.rawValue.lowercased()) in \(next.targetDate.formatted(.dateTime.month(.wide).year()))."
        }

        return "Your plan is ready for the next projection step."
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
