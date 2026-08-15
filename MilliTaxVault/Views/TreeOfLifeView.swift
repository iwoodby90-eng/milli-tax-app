import SwiftUI

// MARK: - TreeOfLifeView — Screen 10: Life events and goals planning
// Header + subtitle | Visual tree/network diagram with glowing nodes

struct TreeOfLifeView: View {
    var onBack: () -> Void = {}

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: MilliSpacing.lg) {
                headerSection
                treeVisualization
            }
            .padding(.horizontal, MilliSpacing.screenHorizontal)
            .padding(.top, MilliSpacing.md)
            .padding(.bottom, 100)
        }
        .background(MilliColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MilliColors.textSecondary)
                }
                .buttonStyle(.plain)

                Text("Tree of Life")
                    .font(MilliFont.screenTitle)
                    .foregroundColor(MilliColors.textPrimary)

                Spacer()
            }

            Text("Life events and goals planning")
                .font(MilliFont.bodySmall)
                .foregroundColor(MilliColors.textSecondary)
                .padding(.leading, 30)
        }
        .padding(.vertical, MilliSpacing.sm)
    }

    // MARK: - Tree Visualization

    private var treeVisualization: some View {
        ZStack {
            // Background ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cyanGlow.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)

            // Connection lines (branches)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let nodes = nodePositions(in: size)

                for node in nodes {
                    var path = Path()
                    path.move(to: center)
                    path.addCurve(
                        to: node,
                        control1: CGPoint(x: (center.x + node.x) / 2, y: center.y),
                        control2: CGPoint(x: node.x, y: (center.y + node.y) / 2)
                    )
                    context.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                MilliColors.cyanGlow.opacity(0.4),
                                MilliColors.cyanGlow.opacity(0.1)
                            ]),
                            startPoint: center,
                            endPoint: node
                        ),
                        lineWidth: 1.5
                    )
                }
            }
            .frame(height: 400)

            // Center trunk node
            VStack(spacing: 4) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 20))
                    .foregroundColor(MilliColors.cyanGlow)
            }
            .frame(width: 50, height: 50)
            .background(
                Circle()
                    .fill(MilliColors.cardBackground)
                    .overlay(
                        Circle()
                            .stroke(MilliColors.cyanGlow.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.3), radius: 8)
            )

            // Goal nodes
            goalNode(icon: "house.fill", label: "Buy a home", amount: "$500K", offset: CGSize(width: -100, height: -140))
            goalNode(icon: "car.fill", label: "New car", amount: "$40K", offset: CGSize(width: -130, height: -20))
            goalNode(icon: "heart.fill", label: "Wedding", amount: "$30K", offset: CGSize(width: 110, height: -120))
            goalNode(icon: "figure.and.child.holdinghands", label: "Baby", amount: "$25K", offset: CGSize(width: -90, height: 120))
            goalNode(icon: "sunset.fill", label: "Retire", amount: "$1.5M", offset: CGSize(width: 110, height: 100))
        }
        .frame(height: 400)
    }

    private func goalNode(icon: String, label: String, amount: String, offset: CGSize) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(MilliColors.cardBackground)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Circle()
                            .stroke(MilliColors.cyanGlow.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: MilliColors.cyanGlow.opacity(0.2), radius: 6)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(MilliColors.cyanGlow)
            }

            VStack(spacing: 2) {
                Text(label)
                    .font(MilliFont.caption)
                    .foregroundColor(MilliColors.textPrimary)
                Text(amount)
                    .font(MilliFont.labelLarge)
                    .foregroundColor(MilliColors.cyanGlow)
            }
        }
        .offset(offset)
    }

    private func nodePositions(in size: CGSize) -> [CGPoint] {
        let cx = size.width / 2
        let cy = size.height / 2
        return [
            CGPoint(x: cx - 100, y: cy - 140),
            CGPoint(x: cx - 130, y: cy - 20),
            CGPoint(x: cx + 110, y: cy - 120),
            CGPoint(x: cx - 90, y: cy + 120),
            CGPoint(x: cx + 110, y: cy + 100),
        ]
    }
}
