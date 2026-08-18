import SwiftUI

// MARK: - TreeOfLifeView
// Milli's signature life-planning visualization. The tree contains only goals
// created by the signed-in user; no seeded dollar amounts or fake milestones.

struct TreeOfLifeView: View {
    var onBack: () -> Void = {}

    @State private var reveal: CGFloat = 0
    @State private var pulse = false
    @State private var showAddEvent = false
    @State private var events: [LifePlanningEvent] = []

    private let nodePositions: [(x: CGFloat, y: CGFloat)] = [
        (0.50, 0.16),
        (0.22, 0.30),
        (0.78, 0.31),
        (0.15, 0.50),
        (0.85, 0.51),
        (0.30, 0.66),
        (0.70, 0.66),
        (0.50, 0.47)
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                header
                planningSummary
                treeStage
                guidanceCard
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showAddEvent) {
            AddLifeEventSheet { event in
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    if events.count < nodePositions.count {
                        events.append(event)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                reveal = 1
            }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.035)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text("Tree of Life")
                    .font(MilliFont.screenTitle)
                    .foregroundStyle(MilliColors.textPrimary)
                Text("YOUR LIFE · YOUR PLAN")
                    .font(MilliFont.caption)
                    .tracking(1.35)
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Spacer()

            Button {
                showAddEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MilliColors.blackGlass)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(MilliColors.cyanGlow)
                            .shadow(color: MilliColors.cyanGlow.opacity(0.30), radius: 8)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add life event")
        }
    }

    private var planningSummary: some View {
        HStack(spacing: 8) {
            summaryMetric(
                label: "PLANNED EVENTS",
                value: events.isEmpty ? "—" : String(events.count),
                icon: "point.3.connected.trianglepath.dotted"
            )

            summaryMetric(
                label: "NEXT EVENT",
                value: nextEventLabel,
                icon: "calendar"
            )
        }
    }

    private func summaryMetric(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 28, height: 28)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(MilliFont.sectionLabel)
                    .foregroundStyle(MilliColors.textTertiary)
                Text(value)
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .milliCard(padding: 10)
    }

    private var treeStage: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "061016"), Color(hex: "030709")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.7)
                    }

                RadialGradient(
                    colors: [MilliColors.cyanGlow.opacity(pulse ? 0.12 : 0.07), Color.clear],
                    center: UnitPoint(x: 0.5, y: 0.54),
                    startRadius: 8,
                    endRadius: geo.size.width * 0.58
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                treeCanvas(size: geo.size)

                ForEach(Array(events.prefix(nodePositions.count).enumerated()), id: \.element.id) { index, event in
                    let position = nodePositions[index]
                    eventNode(event, x: position.x, y: position.y, in: geo.size)
                }

                if events.isEmpty {
                    emptyState
                }
            }
        }
        .frame(height: 520)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.78))
                    .frame(width: 54, height: 54)
                    .overlay(Circle().stroke(MilliColors.cyanGlow.opacity(0.42), lineWidth: 1))
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text("Your tree starts with your first goal")
                .font(MilliFont.headlineSmall)
                .foregroundStyle(MilliColors.textPrimary)

            Text("Add a real life event and Milli will place it on your financial timeline.")
                .font(MilliFont.bodySmall)
                .foregroundStyle(MilliColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)

            Button("Add Life Event") {
                showAddEvent = true
            }
            .font(MilliFont.labelLarge)
            .foregroundStyle(MilliColors.cyanGlow)
            .padding(.top, 2)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.62))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MilliColors.cyanGlow.opacity(0.10), lineWidth: 0.7)
                }
        )
    }

    @ViewBuilder
    private func treeCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let tree = TreeGeometry(size: canvasSize)

            context.stroke(
                tree.fullTree,
                with: .color(MilliColors.cyanGlow.opacity(0.055 * reveal)),
                style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                tree.roots,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "7D5E48"), Color(hex: "D0B69D"), MilliColors.chromeMid]),
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.91),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.73)
                ),
                style: StrokeStyle(lineWidth: 4.4 * reveal, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                tree.fullTree,
                with: .linearGradient(
                    Gradient(colors: [MilliColors.chromeDeep, MilliColors.chromeWhite, MilliColors.cyanGlow, MilliColors.chromeMid]),
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.84),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.12)
                ),
                style: StrokeStyle(lineWidth: 4.2 * reveal, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                tree.highlight,
                with: .color(Color.white.opacity(0.58 * reveal)),
                style: StrokeStyle(lineWidth: 0.9, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                tree.ground,
                with: .linearGradient(
                    Gradient(colors: [Color.clear, MilliColors.cyanGlow.opacity(0.72), Color.clear]),
                    startPoint: CGPoint(x: 0, y: canvasSize.height * 0.90),
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.90)
                ),
                style: StrokeStyle(lineWidth: 1.4 * reveal, lineCap: .round)
            )

            for point in tree.growthNodes {
                let halo = CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)
                let core = CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)
                context.fill(Path(ellipseIn: halo), with: .color(MilliColors.cyanGlow.opacity(0.08 * reveal)))
                context.fill(Path(ellipseIn: core), with: .color(MilliColors.cyanGlow.opacity(0.90 * reveal)))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func eventNode(
        _ event: LifePlanningEvent,
        x: CGFloat,
        y: CGFloat,
        in size: CGSize
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.90))
                    .frame(width: 46, height: 46)
                    .overlay {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [MilliColors.chromeDeep, MilliColors.chromeWhite, MilliColors.cyanGlow, MilliColors.chromeMid],
                                    center: .center
                                ),
                                lineWidth: 2.0
                            )
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(pulse ? 0.42 : 0.22), radius: pulse ? 9 : 5)

                Image(systemName: event.type.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text(event.type.rawValue)
                .font(MilliFont.labelLarge)
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(compactCurrency(event.estimatedCost))
                .font(MilliFont.bodySmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
        }
        .frame(width: 105)
        .position(x: size.width * x, y: size.height * y)
        .opacity(reveal)
        .scaleEffect(0.90 + 0.10 * reveal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.type.rawValue), target \(compactCurrency(event.estimatedCost)), \(event.targetDate.formatted(date: .abbreviated, time: .omitted))")
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

    private var guidanceCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MilliColors.cyanGlow)
                .frame(width: 32, height: 32)
                .background(Circle().fill(MilliColors.cyanGlow.opacity(0.08)))

            VStack(alignment: .leading, spacing: 3) {
                Text("Your plan grows with you")
                    .font(MilliFont.headlineSmall)
                    .foregroundStyle(MilliColors.textPrimary)
                Text(events.isEmpty
                     ? "Add only the milestones that matter to you. Milli will never populate your financial future with invented assumptions."
                     : "Each event is based on information you entered. Add, revise, or remove milestones as your plans change.")
                    .font(MilliFont.bodySmall)
                    .foregroundStyle(MilliColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .milliCard(padding: 12)
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

private struct TreeGeometry {
    let size: CGSize

    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }

    var fullTree: Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.46, y: h * 0.84))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.28), control1: CGPoint(x: w * 0.45, y: h * 0.68), control2: CGPoint(x: w * 0.47, y: h * 0.43))
        p.move(to: CGPoint(x: w * 0.54, y: h * 0.84))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.28), control1: CGPoint(x: w * 0.55, y: h * 0.68), control2: CGPoint(x: w * 0.53, y: h * 0.43))

        branch(&p, from: (0.49, 0.55), to: (0.14, 0.49), c1: (0.39, 0.49), c2: (0.24, 0.47))
        branch(&p, from: (0.49, 0.45), to: (0.21, 0.30), c1: (0.40, 0.39), c2: (0.31, 0.31))
        branch(&p, from: (0.49, 0.36), to: (0.35, 0.17), c1: (0.43, 0.29), c2: (0.38, 0.21))
        branch(&p, from: (0.31, 0.36), to: (0.16, 0.22), c1: (0.25, 0.31), c2: (0.20, 0.25))
        branch(&p, from: (0.34, 0.50), to: (0.25, 0.65), c1: (0.29, 0.55), c2: (0.27, 0.61))

        branch(&p, from: (0.51, 0.55), to: (0.86, 0.50), c1: (0.61, 0.49), c2: (0.76, 0.48))
        branch(&p, from: (0.51, 0.45), to: (0.79, 0.31), c1: (0.60, 0.39), c2: (0.70, 0.31))
        branch(&p, from: (0.51, 0.36), to: (0.65, 0.17), c1: (0.57, 0.29), c2: (0.62, 0.21))
        branch(&p, from: (0.69, 0.36), to: (0.84, 0.22), c1: (0.75, 0.31), c2: (0.80, 0.25))
        branch(&p, from: (0.66, 0.50), to: (0.75, 0.65), c1: (0.71, 0.55), c2: (0.73, 0.61))
        branch(&p, from: (0.50, 0.31), to: (0.50, 0.12), c1: (0.49, 0.24), c2: (0.50, 0.17))
        return p
    }

    var highlight: Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.49, y: h * 0.81))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.30), control1: CGPoint(x: w * 0.48, y: h * 0.63), control2: CGPoint(x: w * 0.49, y: h * 0.42))
        branch(&p, from: (0.50, 0.43), to: (0.22, 0.30), c1: (0.41, 0.38), c2: (0.31, 0.32))
        branch(&p, from: (0.50, 0.43), to: (0.78, 0.31), c1: (0.59, 0.38), c2: (0.69, 0.32))
        return p
    }

    var roots: Path {
        var p = Path()
        branch(&p, from: (0.48, 0.82), to: (0.24, 0.91), c1: (0.42, 0.87), c2: (0.32, 0.90))
        branch(&p, from: (0.50, 0.83), to: (0.50, 0.93), c1: (0.48, 0.88), c2: (0.51, 0.91))
        branch(&p, from: (0.52, 0.82), to: (0.76, 0.91), c1: (0.58, 0.87), c2: (0.68, 0.90))
        return p
    }

    var ground: Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.12, y: h * 0.92))
        p.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.92), control1: CGPoint(x: w * 0.34, y: h * 0.88), control2: CGPoint(x: w * 0.66, y: h * 0.88))
        return p
    }

    var growthNodes: [CGPoint] {
        [
            CGPoint(x: w * 0.50, y: h * 0.28),
            CGPoint(x: w * 0.31, y: h * 0.36),
            CGPoint(x: w * 0.69, y: h * 0.36),
            CGPoint(x: w * 0.34, y: h * 0.50),
            CGPoint(x: w * 0.66, y: h * 0.50)
        ]
    }

    private func branch(
        _ path: inout Path,
        from: (CGFloat, CGFloat),
        to: (CGFloat, CGFloat),
        c1: (CGFloat, CGFloat),
        c2: (CGFloat, CGFloat)
    ) {
        path.move(to: CGPoint(x: w * from.0, y: h * from.1))
        path.addCurve(
            to: CGPoint(x: w * to.0, y: h * to.1),
            control1: CGPoint(x: w * c1.0, y: h * c1.1),
            control2: CGPoint(x: w * c2.0, y: h * c2.1)
        )
    }
}

#Preview {
    TreeOfLifeView()
        .preferredColorScheme(.dark)
}
