import SwiftUI
import UIKit

// MARK: - TreeOfLifeView
// Canonical Tree of Life experience. The tree is the hero; financial planning
// information supports it instead of competing with it. Production values remain
// grounded in user-entered data. Populated reference values exist only in DEBUG
// screenshot mode for visual QA.

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
                type: .businessLaunch,
                targetDate: calendar.date(byAdding: .month, value: 10, to: now) ?? now,
                estimatedCost: 18_000
            ),
            LifePlanningEvent(
                type: .marriage,
                targetDate: calendar.date(byAdding: .year, value: 2, to: now) ?? now,
                estimatedCost: 25_000
            ),
            LifePlanningEvent(
                type: .child,
                targetDate: calendar.date(byAdding: .year, value: 5, to: now) ?? now,
                estimatedCost: 35_000
            ),
            LifePlanningEvent(
                type: .homePurchase,
                targetDate: calendar.date(byAdding: .year, value: 7, to: now) ?? now,
                estimatedCost: 120_000
            ),
            LifePlanningEvent(
                type: .education,
                targetDate: calendar.date(byAdding: .year, value: 11, to: now) ?? now,
                estimatedCost: 60_000
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
                VStack(spacing: 18) {
                    header
                    treeStage(width: proxy.size.width - (MilliSpacing.screenHorizontal * 2))
                    planningSummary
                    planningAdjustments
                    aiPlanningInsight
                }
                .padding(.horizontal, MilliSpacing.screenHorizontal)
                .padding(.top, 8)
                .padding(.bottom, MilliSpacing.bottomContentClearance)
            }
            .background(background)
        }
        .sheet(isPresented: $showAddEvent) {
            AddLifeEventSheet { event in
                withAnimation(.spring(response: 0.48, dampingFraction: 0.82)) {
                    events.append(event)
                }
            }
        }
        .onAppear {
            guard !UIAccessibility.isReduceMotionEnabled else { return }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: Background / header

    private var background: some View {
        ZStack {
            MilliColors.background.ignoresSafeArea()
            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(0.055), Color.clear],
                center: UnitPoint(x: 0.50, y: 0.23),
                startRadius: 0,
                endRadius: 330
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
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Tree of Life")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)

                Text("YOUR FUTURE · VISUALIZED")
                    .font(MilliFont.caption)
                    .tracking(1.35)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            Button {
                showAddEvent = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Event")
                }
                .font(.custom("Inter-SemiBold", size: 10, relativeTo: .caption))
                .foregroundStyle(MilliColors.cyanGlow)
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.025))
                        .overlay {
                            Capsule().stroke(MilliColors.cyanGlow.opacity(0.34), lineWidth: 0.8)
                        }
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add life event")
        }
    }

    // MARK: Hero tree

    private func treeStage(width: CGFloat) -> some View {
        let height = min(max(width * 1.50, 560), 720)

        return ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "02070A"))

            Image("treeoflife-bg")
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()
                .opacity(0.98)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.50),
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [MilliColors.cyanGlow.opacity(glowPulse ? 0.13 : 0.07), Color.clear],
                center: UnitPoint(x: 0.51, y: 0.50),
                startRadius: 30,
                endRadius: width * 0.58
            )

            projectionHeader
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 22)

            if !events.isEmpty {
                milestoneOverlay(width: width, height: height)
            }

            if events.isEmpty {
                heroEmptyState
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
            } else {
                heroFooter
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.26), MilliColors.cyanGlow.opacity(0.26), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        }
        .shadow(color: MilliColors.cyanGlow.opacity(0.07), radius: 22, y: 8)
    }

    private var projectionHeader: some View {
        VStack(spacing: 4) {
            Text("PROJECTED NET WORTH")
                .font(MilliFont.sectionLabel)
                .tracking(1.2)
                .foregroundStyle(Color.white.opacity(0.66))

            Text(visualFixtureMode ? "$5,284,170" : "—")
                .font(.custom("Sora-SemiBold", size: 30, relativeTo: .title))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(visualFixtureMode ? "at age 65" : "Complete your financial inputs to activate projection")
                .font(MilliFont.caption)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.34))
                .blur(radius: 0.2)
        )
    }

    private func milestoneOverlay(width: CGFloat, height: CGFloat) -> some View {
        let visibleEvents = Array(events.sorted(by: { $0.targetDate < $1.targetDate }).prefix(6))

        return ZStack {
            ForEach(Array(visibleEvents.enumerated()), id: \.offset) { index, event in
                milestoneNode(event)
                    .position(milestonePosition(index: index, width: width, height: height))
            }

            if visualFixtureMode {
                centralGoalNode
                    .position(x: width * 0.51, y: height * 0.49)
            }
        }
    }

    private func milestoneNode(_ event: LifePlanningEvent) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "17232A"), Color.black],
                            center: UnitPoint(x: 0.42, y: 0.35),
                            startRadius: 1,
                            endRadius: 24
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.48), MilliColors.cyanGlow.opacity(0.72), Color.white.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.24), radius: 7)

                Image(systemName: event.type.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text(event.type.rawValue)
                .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(event.targetDate.formatted(.dateTime.year()))
                .font(.custom("Inter-Regular", size: 8.5, relativeTo: .caption2))
                .foregroundStyle(MilliColors.cyanGlow)
        }
        .frame(width: 94)
    }

    private var centralGoalNode: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.78))
                    .frame(width: 58, height: 58)
                    .overlay {
                        Circle().stroke(Color.white.opacity(0.30), lineWidth: 1)
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 9)

                Image(systemName: "diamond.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(MilliColors.silverBright)
            }

            Text("Financial Freedom")
                .font(.custom("Inter-SemiBold", size: 9.5, relativeTo: .caption2))
                .foregroundStyle(MilliColors.textPrimary)
            Text("Your goal")
                .font(.custom("Inter-Regular", size: 8.5, relativeTo: .caption2))
                .foregroundStyle(MilliColors.cyanGlow)
        }
        .frame(width: 112)
    }

    private func milestonePosition(index: Int, width: CGFloat, height: CGFloat) -> CGPoint {
        let positions: [(CGFloat, CGFloat)] = [
            (0.22, 0.30),
            (0.15, 0.45),
            (0.22, 0.61),
            (0.79, 0.31),
            (0.85, 0.47),
            (0.78, 0.63)
        ]
        let point = positions[index % positions.count]
        return CGPoint(x: width * point.0, y: height * point.1)
    }

    private var heroEmptyState: some View {
        VStack(spacing: 9) {
            Text("Your future grows from the decisions you make today.")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Add the milestones that matter to you. Milli will build the timeline without inventing assumptions.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showAddEvent = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "plus")
                    Text("Add First Life Event")
                }
                .font(MilliFont.labelLarge)
                .foregroundStyle(Color.black)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background(Capsule().fill(MilliColors.cyanGlow))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.58))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.14), lineWidth: 0.7)
                }
        )
    }

    private var heroFooter: some View {
        HStack(spacing: 8) {
            footerMetric(title: "LIFE EVENTS", value: String(events.count), accent: MilliColors.cyanGlow)
            footerMetric(title: "PLANNED VALUE", value: compactCurrency(plannedGoalValue), accent: Color(hex: "D9B58B"))
        }
    }

    private func footerMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(MilliFont.sectionLabel)
                .foregroundStyle(accent)
            Text(value)
                .font(MilliFont.numericMedium)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.black.opacity(0.56))
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(accent.opacity(0.18), lineWidth: 0.7)
                }
        )
    }

    // MARK: Planning summary

    private var planningSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("YOUR PLAN")

            HStack(spacing: 0) {
                summaryMetric(
                    title: "Projected Net Worth",
                    value: visualFixtureMode ? "$5.28M" : "—",
                    detail: visualFixtureMode ? "Age 65" : "Awaiting inputs",
                    accent: MilliColors.cyanGlow
                )

                Rectangle().fill(Color.white.opacity(0.07)).frame(width: 1, height: 72)

                summaryMetric(
                    title: "Monthly Investment",
                    value: visualFixtureMode ? "$2,600" : "—",
                    detail: visualFixtureMode ? "Current plan" : "Not set",
                    accent: MilliColors.positive
                )

                Rectangle().fill(Color.white.opacity(0.07)).frame(width: 1, height: 72)

                summaryMetric(
                    title: "Life Goals",
                    value: compactCurrency(plannedGoalValue),
                    detail: "Planned targets",
                    accent: Color(hex: "D9B58B")
                )
            }
            .padding(.vertical, 10)
            .background(integratedSurface)
        }
    }

    private func summaryMetric(title: String, value: String, detail: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.custom("Inter-SemiBold", size: 8.5, relativeTo: .caption2))
                .tracking(0.45)
                .foregroundStyle(MilliColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.custom("Sora-SemiBold", size: 16, relativeTo: .headline))
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(detail)
                .font(MilliFont.caption)
                .foregroundStyle(accent)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }

    // MARK: Planning adjustments

    private var planningAdjustments: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionHeader("WHAT IF?")
                Spacer()
                Text("See the impact before you change the plan")
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            if visualFixtureMode {
                adjustmentRow(
                    icon: "arrow.up.right",
                    title: "Increase Savings",
                    detail: "+2% annual contribution",
                    impact: "+$1.2M",
                    positive: true
                )
                adjustmentRow(
                    icon: "clock.arrow.circlepath",
                    title: "Retire Earlier",
                    detail: "Model age 60",
                    impact: "-$186K",
                    positive: false
                )
                adjustmentRow(
                    icon: "airplane",
                    title: "Travel More",
                    detail: "Add lifestyle spending",
                    impact: "-$42K",
                    positive: false
                )
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(MilliColors.cyanGlow)
                    Text("Scenario analysis activates when your projection inputs are complete.")
                        .font(MilliFont.bodySmall)
                        .foregroundStyle(MilliColors.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(14)
        .background(integratedSurface)
    }

    private func adjustmentRow(icon: String, title: String, detail: String, impact: String, positive: Bool) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 30, height: 30)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.custom("Inter-SemiBold", size: 12.5, relativeTo: .footnote))
                    .foregroundStyle(MilliColors.textPrimary)
                Text(detail)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }

            Spacer()

            Text(impact)
                .font(.custom("Sora-SemiBold", size: 12, relativeTo: .footnote))
                .foregroundStyle(positive ? MilliColors.positive : MilliColors.textSecondary)
        }
    }

    // MARK: Milli AI

    private var aiPlanningInsight: some View {
        HStack(spacing: 13) {
            MilliAICharacterView(size: 92, animated: true)
                .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 5) {
                Text("MILLI AI")
                    .font(.custom("Inter-SemiBold", size: 10))
                    .tracking(1.0)
                    .foregroundStyle(MilliColors.cyanGlow)
                Text("Plan with context")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(aiInsightText)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(MilliFont.sectionLabel)
            .tracking(1.15)
            .foregroundStyle(MilliColors.textSecondary)
    }

    private var integratedSurface: some View {
        RoundedRectangle(cornerRadius: 17, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color(hex: "0D151A"), Color(hex: "080C0F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(Color.white.opacity(0.075), lineWidth: 0.7)
            }
    }

    // MARK: Derived values

    private var plannedGoalValue: Double {
        events.reduce(0) { $0 + $1.estimatedCost }
    }

    private var aiInsightText: String {
        if visualFixtureMode {
            return "Increasing annual savings by 2% could materially strengthen the long-term plan while preserving your current milestones."
        }

        guard !events.isEmpty else {
            return "Add your first life event and I’ll organize the milestones that matter to your future plan."
        }

        let next = events.sorted(by: { $0.targetDate < $1.targetDate }).first
        if let next {
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
