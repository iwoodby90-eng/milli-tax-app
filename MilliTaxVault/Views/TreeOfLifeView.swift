import SwiftUI

// MARK: - TreeOfLifeView
// Signature life-planning visualization. Native SwiftUI Canvas — not a static image.

struct TreeOfLifeView: View {
    var onBack: () -> Void = {}
    @State private var reveal: CGFloat = 0

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

                    eventNode(
                        icon: "house.fill",
                        title: "Buy a home",
                        amount: "$500K",
                        x: 0.52,
                        y: 0.18,
                        in: geo.size
                    )
                    eventNode(
                        icon: "car.fill",
                        title: "New car",
                        amount: "$40K",
                        x: 0.20,
                        y: 0.32,
                        in: geo.size
                    )
                    eventNode(
                        icon: "person.2.fill",
                        title: "Wedding",
                        amount: "$30K",
                        x: 0.80,
                        y: 0.36,
                        in: geo.size
                    )
                    eventNode(
                        icon: "heart.fill",
                        title: "Baby",
                        amount: "$25K",
                        x: 0.25,
                        y: 0.60,
                        in: geo.size
                    )
                    eventNode(
                        icon: "sun.horizon.fill",
                        title: "Retire",
                        amount: "$1.5M",
                        x: 0.76,
                        y: 0.62,
                        in: geo.size
                    )
                }
            }
            .frame(minHeight: 520)
            .padding(.horizontal, 4)
            .padding(.bottom, MilliSpacing.bottomContentClearance)
        }
        .background(MilliColors.background.ignoresSafeArea())
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

                Button {} label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MilliColors.textSecondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
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

            // Soft cyan halo behind the entire structure.
            for width in stride(from: 18.0, through: 5.0, by: -4.0) {
                context.stroke(
                    tree.fullTree,
                    with: .color(MilliColors.cyanGlow.opacity(width == 18 ? 0.025 : 0.045)),
                    style: StrokeStyle(lineWidth: width * reveal, lineCap: .round, lineJoin: .round)
                )
            }

            // Silver-warm root understructure echoes the reference's physical tree roots.
            context.stroke(
                tree.roots,
                with: .linearGradient(
                    Gradient(colors: [Color(hex: "A77B52").opacity(0.55), MilliColors.cyanGlow.opacity(0.42)]),
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.86),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.70)
                ),
                style: StrokeStyle(lineWidth: 3.0 * reveal, lineCap: .round, lineJoin: .round)
            )

            // Main trunk and branches.
            context.stroke(
                tree.fullTree,
                with: .linearGradient(
                    Gradient(colors: [MilliColors.cyanGlow, Color(hex: "57F3FF"), MilliColors.deepCyan]),
                    startPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.82),
                    endPoint: CGPoint(x: canvasSize.width * 0.5, y: canvasSize.height * 0.14)
                ),
                style: StrokeStyle(lineWidth: 3.1 * reveal, lineCap: .round, lineJoin: .round)
            )

            // Ground line/root sweep.
            context.stroke(
                tree.ground,
                with: .linearGradient(
                    Gradient(colors: [Color.clear, MilliColors.cyanGlow, Color.clear]),
                    startPoint: CGPoint(x: 0, y: canvasSize.height * 0.86),
                    endPoint: CGPoint(x: canvasSize.width, y: canvasSize.height * 0.86)
                ),
                style: StrokeStyle(lineWidth: 1.7 * reveal, lineCap: .round)
            )

            // Small illuminated growth nodes along branches.
            for point in tree.growthNodes {
                let rect = CGRect(x: point.x - 5, y: point.y - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: rect), with: .color(MilliColors.cyanGlow.opacity(reveal)))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func eventNode(
        icon: String,
        title: String,
        amount: String,
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

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MilliColors.cyanGlow)
            }

            Text(title)
                .font(MilliFont.labelLarge)
                .foregroundStyle(MilliColors.textPrimary)
                .lineLimit(1)

            Text(amount)
                .font(MilliFont.bodySmall)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textSecondary)
        }
        .position(x: size.width * x, y: size.height * y)
        .opacity(reveal)
        .scaleEffect(0.92 + 0.08 * reveal)
    }
}

private struct TreeGeometry {
    let size: CGSize

    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }
    private var trunkBase: CGPoint { CGPoint(x: w * 0.5, y: h * 0.82) }
    private var crown: CGPoint { CGPoint(x: w * 0.5, y: h * 0.30) }

    var fullTree: Path {
        var p = Path()

        // Trunk — two gently diverging structural lines merge into the crown.
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

        // Left primary branch.
        p.move(to: CGPoint(x: w * 0.49, y: h * 0.52))
        p.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.32),
            control1: CGPoint(x: w * 0.42, y: h * 0.44),
            control2: CGPoint(x: w * 0.30, y: h * 0.34)
        )

        // Left upper branch.
        p.move(to: CGPoint(x: w * 0.49, y: h * 0.43))
        p.addCurve(
            to: CGPoint(x: w * 0.36, y: h * 0.20),
            control1: CGPoint(x: w * 0.43, y: h * 0.35),
            control2: CGPoint(x: w * 0.39, y: h * 0.27)
        )

        // Left-lower event branch.
        p.move(to: CGPoint(x: w * 0.47, y: h * 0.61))
        p.addCurve(
            to: CGPoint(x: w * 0.24, y: h * 0.59),
            control1: CGPoint(x: w * 0.38, y: h * 0.55),
            control2: CGPoint(x: w * 0.31, y: h * 0.57)
        )

        // Center upper branch / home node.
        p.move(to: CGPoint(x: w * 0.50, y: h * 0.36))
        p.addCurve(
            to: CGPoint(x: w * 0.52, y: h * 0.18),
            control1: CGPoint(x: w * 0.49, y: h * 0.29),
            control2: CGPoint(x: w * 0.51, y: h * 0.23)
        )

        // Right primary branch.
        p.move(to: CGPoint(x: w * 0.51, y: h * 0.50))
        p.addCurve(
            to: CGPoint(x: w * 0.81, y: h * 0.35),
            control1: CGPoint(x: w * 0.59, y: h * 0.43),
            control2: CGPoint(x: w * 0.70, y: h * 0.37)
        )

        // Right upper branch.
        p.move(to: CGPoint(x: w * 0.52, y: h * 0.40))
        p.addCurve(
            to: CGPoint(x: w * 0.67, y: h * 0.22),
            control1: CGPoint(x: w * 0.58, y: h * 0.34),
            control2: CGPoint(x: w * 0.63, y: h * 0.27)
        )

        // Right-lower retirement branch.
        p.move(to: CGPoint(x: w * 0.53, y: h * 0.62))
        p.addCurve(
            to: CGPoint(x: w * 0.76, y: h * 0.61),
            control1: CGPoint(x: w * 0.61, y: h * 0.56),
            control2: CGPoint(x: w * 0.69, y: h * 0.58)
        )

        // Fine secondary tips.
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
