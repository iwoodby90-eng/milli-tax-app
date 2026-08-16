import SwiftUI

// MARK: - TreeOfLifeView
// Signature life-planning visualization. Native SwiftUI Canvas — not a static image.
// Nodes are real planning models and can be added through AddLifeEventSheet.

struct TreeOfLifeView: View {
    var onBack: () -> Void = {}

    @State private var reveal: CGFloat = 0
    @State private var showAddEvent = false
    @State private var events: [LifePlanningEvent] = LifePlanningEvent.seededTree

    private let nodePositions: [(x: CGFloat, y: CGFloat)] = [
        (0.52, 0.18),
        (0.20, 0.32),
        (0.80, 0.36),
        (0.25, 0.60),
        (0.76, 0.62),
        (0.64, 0.25)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            GeometryReader { geo in
                ZStack {
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.09), Color.clear],
                        center: UnitPoint(x: 0.5, y: 0.55),
                        startRadius: 10,
                        endRadius: geo.size.width * 0.54
                    )

                    treeCanvas(size: geo.size)

                    ForEach(Array(events.prefix(nodePositions.count).enumerated()), id: \.element.id) { index, event in
                        let position = nodePositions[index]
                        eventNode(event, x: position.x, y: position.y, in: geo.size)
                    }
                }
            }
            .frame(minHeight: 520)
            .padding(.horizontal, 4)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
        .sheet(isPresented: $showAddEvent) {
            AddLifeEventSheet { event in
                withAnimation(.easeOut(duration: 0.35)) {
                    if events.count < nodePositions.count {
                        events.append(event)
                    } else {
                        // Preserve the visual density of the approved tree while retaining
                        // the newest plan in the currently visible set.
                        events[events.count - 1] = event
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.25)) {
                reveal = 1
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Color.white.opacity(0.035)))
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    showAddEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(MilliColors.blackGlass)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(MilliColors.cyanGlow))
                        .shadow(color: MilliColors.cyanGlow.opacity(0.20), radius: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add life event")
            }

            Text("Tree of Life")
                .font(MilliFont.displaySmall)
                .foregroundStyle(MilliColors.textPrimary)

            Text("Life events and goals planning")
                .font(MilliFont.bodyMedium)
                .foregroundStyle(MilliColors.textSecondary)
        }
        .padding(.horizontal, MilliSpacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func treeCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let tree = TreeGeometry(size: canvasSize)

            for width in stride(from: 18.0, through: 5.0, by: -4.0) {
                context.stroke(
                    tree.fullTree,
                    with: .color(MilliColors.cyanGlow.opacity(width == 18 ? 0.025 : 0.045)),
                    style: StrokeStyle(lineWidth: width * reveal, lineCap: .round, lineJoin: .round)
                )
            }

            context.stroke(
                tree.roots,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "A77B52").opacity(0.55), MilliColors.cyanGlow.opacity(0.42)]),
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.86),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.70)
                ),
                style: StrokeStyle(lineWidth: 3.0 * reveal, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                tree.fullTree,
                with: .linearGradient(
                    Gradient(colors: [MilliColors.cyanGlow, Color(hex: "57F3FF"), MilliColors.deepCyan]),
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.82),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.14)
                ),
                style: StrokeStyle(lineWidth: 3.1 * reveal, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                tree.ground,
                with: .linearGradient(
                    Gradient(colors: [Color.clear, MilliColors.cyanGlow, Color.clear]),
                    startPoint: CGPoint(x: 0, y: canvasSize.height * 0.86),
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.86)
                ),
                style: StrokeStyle(lineWidth: 1.7 * reveal, lineCap: .round)
            )

            for point in tree.growthNodes {
                let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: rect), with: .color(MilliColors.cyanGlow.opacity(reveal)))
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
                    .fill(Color(hex: "0A171D"))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Circle()
                            .stroke(MilliColors.cyanGlow.opacity(0.68), lineWidth: 1.4)
                    }
                    .shadow(color: MilliColors.cyanGlow.opacity(0.36), radius: 8)

                Image(systemName: event.type.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text(event.type.rawValue)
                .font(MilliFont.labelLarge)
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)

            Text(compactCurrency(event.estimatedCost))
                .font(MilliFont.bodySmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
        }
        .position(x: size.width * x, y: size.height * y)
        .opacity(reveal)
        .scaleEffect(0.92 + 0.08 * reveal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.type.rawValue), target \(compactCurrency(event.estimatedCost)), \(event.targetDate.formatted(date: .abbreviated, time: .omitted))")
    }

    private func compactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "$%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "$%.0fK", value / 1_000) }
        return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

private extension LifePlanningEvent {
    static var seededTree: [LifePlanningEvent] {
        let calendar = Calendar.current
        let now = Date()
        func date(years: Int) -> Date {
            calendar.date(byAdding: .year, value: years, to: now) ?? now
        }

        return [
            LifePlanningEvent(type: .homePurchase, targetDate: date(years: 4), estimatedCost: 500_000),
            LifePlanningEvent(type: .vehicle, targetDate: date(years: 2), estimatedCost: 40_000),
            LifePlanningEvent(type: .marriage, targetDate: date(years: 3), estimatedCost: 30_000),
            LifePlanningEvent(type: .child, targetDate: date(years: 5), estimatedCost: 25_000),
            LifePlanningEvent(type: .retirement, targetDate: date(years: 21), estimatedCost: 1_500_000)
        ]
    }
}

private struct TreeGeometry {
    let size: CGSize

    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }
    private var crown: CGPoint { CGPoint(x: w * 0.5, y: h * 0.30) }

    var fullTree: Path {
        var p = Path()

        p.move(to: CGPoint(x: w * 0.46, y: h * 0.82))
        p.addCurve(
            to: crown,
            control1: CGPoint(x: w * 0.48, y: h * 0.70),
            control2: CGPoint(x: w * 0.48, y: h * 0.47)
        )

        p.move(to: CGPoint(x: w * 0.54, y: h * 0.82))
        p.addCurve(
            to: crown,
            control1: CGPoint(x: w * 0.52, y: h * 0.70),
            control2: CGPoint(x: w * 0.52, y: h * 0.47)
        )

        p.move(to: CGPoint(x: w * 0.49, y: h * 0.52))
        p.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.32),
            control1: CGPoint(x: w * 0.42, y: h * 0.44),
            control2: CGPoint(x: w * 0.30, y: h * 0.34)
        )

        p.move(to: CGPoint(x: w * 0.49, y: h * 0.43))
        p.addCurve(
            to: CGPoint(x: w * 0.36, y: h * 0.20),
            control1: CGPoint(x: w * 0.43, y: h * 0.35),
            control2: CGPoint(x: w * 0.39, y: h * 0.27)
        )

        p.move(to: CGPoint(x: w * 0.47, y: h * 0.61))
        p.addCurve(
            to: CGPoint(x: w * 0.24, y: h * 0.59),
            control1: CGPoint(x: w * 0.38, y: h * 0.55),
            control2: CGPoint(x: w * 0.31, y: h * 0.57)
        )

        p.move(to: CGPoint(x: w * 0.50, y: h * 0.36))
        p.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.18),
            control1: CGPoint(x: w * 0.49, y: h * 0.29),
            control2: CGPoint(x: w * 0.51, y: h * 0.23)
        )

        p.move(to: CGPoint(x: w * 0.51, y: h * 0.50))
        p.addCurve(
            to: CGPoint(x: w * 0.81, y: h * 0.35),
            control1: CGPoint(x: w * 0.59, y: h * 0.43),
            control2: CGPoint(x: w * 0.70, y: h * 0.37)
        )

        p.move(to: CGPoint(x: w * 0.52, y: h * 0.40))
        p.addCurve(
            to: CGPoint(x: w * 0.67, y: h * 0.22),
            control1: CGPoint(x: w * 0.58, y: h * 0.34),
            control2: CGPoint(x: w * 0.63, y: h * 0.27)
        )

        p.move(to: CGPoint(x: w * 0.53, y: h * 0.62))
        p.addCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.61),
            control1: CGPoint(x: w * 0.61, y: h * 0.56),
            control2: CGPoint(x: w * 0.69, y: h * 0.58)
        )

        p.move(to: CGPoint(x: w * 0.34, y: h * 0.40))
        p.addCurve(
            to: CGPoint(x: w * 0.23, y: h * 0.25),
            control1: CGPoint(x: w * 0.29, y: h * 0.34),
            control2: CGPoint(x: w * 0.26, y: h * 0.28)
        )
        p.move(to: CGPoint(x: w * 0.65, y: h * 0.40))
        p.addCurve(
            to: CGPoint(x: w * 0.75, y: h * 0.25),
            control1: CGPoint(x: w * 0.70, y: h * 0.34),
            control2: CGPoint(x: w * 0.73, y: h * 0.29)
        )

        return p
    }

    var roots: Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.48, y: h * 0.80))
        p.addCurve(to: CGPoint(x: w * 0.30, y: h * 0.90), control1: CGPoint(x: w * 0.44, y: h * 0.85), control2: CGPoint(x: w * 0.36, y: h * 0.88))
        p.move(to: CGPoint(x: w * 0.50, y: h * 0.81))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.91), control1: CGPoint(x: w * 0.48, y: h * 0.86), control2: CGPoint(x: w * 0.51, y: h * 0.88))
        p.move(to: CGPoint(x: w * 0.52, y: h * 0.80))
        p.addCurve(to: CGPoint(x: w * 0.70, y: h * 0.90), control1: CGPoint(x: w * 0.56, y: h * 0.85), control2: CGPoint(x: w * 0.64, y: h * 0.88))
        return p
    }

    var ground: Path {
        var p = Path()
        p.move(to: CGPoint(x: w * 0.20, y: h * 0.88))
        p.addCurve(
            to: CGPoint(x: w * 0.80, y: h * 0.88),
            control1: CGPoint(x: w * 0.36, y: h * 0.84),
            control2: CGPoint(x: w * 0.64, y: h * 0.84)
        )
        return p
    }

    var growthNodes: [CGPoint] {
        [
            CGPoint(x: w * 0.31, y: h * 0.38),
            CGPoint(x: w * 0.40, y: h * 0.29),
            CGPoint(x: w * 0.44, y: h * 0.49),
            CGPoint(x: w * 0.57, y: h * 0.31),
            CGPoint(x: w * 0.63, y: h * 0.43),
            CGPoint(x: w * 0.69, y: h * 0.53)
        ]
    }
}
