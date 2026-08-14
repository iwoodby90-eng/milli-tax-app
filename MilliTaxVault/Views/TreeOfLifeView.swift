import SwiftUI

// MARK: - TreeOfLifeView — Life Events + Future Planner
// Cinematic timeline visualization connecting past milestones to future goals.
// Uses the Tree of Life visual metaphor — roots (past), trunk (now), branches (future).

struct LifeEvent: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let date: String
    let amount: String?
    let isPast: Bool
    let isMilestone: Bool
}

struct TreeOfLifeView: View {
    @State private var selectedFilter: TreeFilter = .all
    @State private var treeGrowth: CGFloat = 0
    @Environment(\.dismiss) private var dismiss
    
    enum TreeFilter: String, CaseIterable {
        case all = "All"
        case past = "Past"
        case future = "Future"
    }
    
    private let lifeEvents: [LifeEvent] = [
        // Past events (roots)
        LifeEvent(icon: "car.fill", title: "First Vehicle", subtitle: "2019 Honda Accord registered", date: "Mar 2019", amount: nil, isPast: true, isMilestone: true),
        LifeEvent(icon: "briefcase.fill", title: "Started Business", subtitle: "LLC formed, first deduction year", date: "Jan 2021", amount: "$4,200 saved", isPast: true, isMilestone: true),
        LifeEvent(icon: "road.lanes", title: "10,000 Miles Tracked", subtitle: "Lifetime mileage milestone", date: "Sep 2022", amount: "$6,550 deducted", isPast: true, isMilestone: false),
        LifeEvent(icon: "chart.line.uptrend.xyaxis", title: "First Investment", subtitle: "Opened brokerage account", date: "Feb 2023", amount: nil, isPast: true, isMilestone: true),
        LifeEvent(icon: "dollarsign.circle.fill", title: "Tax Savings Goal Met", subtitle: "Annual target exceeded", date: "Dec 2024", amount: "$12,400 saved", isPast: true, isMilestone: false),
        // Future events (branches)
        LifeEvent(icon: "house.fill", title: "Home Purchase", subtitle: "Target down payment funded", date: "Q2 2026", amount: "$80,000 goal", isPast: false, isMilestone: true),
        LifeEvent(icon: "building.2.fill", title: "Second Business", subtitle: "Expand into new market", date: "2027", amount: nil, isPast: false, isMilestone: true),
        LifeEvent(icon: "airplane", title: "Financial Freedom", subtitle: "Passive income covers expenses", date: "2030", amount: "$8,400/mo", isPast: false, isMilestone: true),
        LifeEvent(icon: "leaf.fill", title: "Early Retirement", subtitle: "Fully funded at age 55", date: "2035", amount: "$2.4M target", isPast: false, isMilestone: true),
    ]
    
    private var filteredEvents: [LifeEvent] {
        switch selectedFilter {
        case .all: return lifeEvents
        case .past: return lifeEvents.filter { $0.isPast }
        case .future: return lifeEvents.filter { !$0.isPast }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xxl) {
                    headerSection
                    treeVisualization
                    filterRow
                    timelineSection
                    Spacer().frame(height: 120)
                }
            }
            .background(MilliColors.obsidian.ignoresSafeArea())
            
            MilliAIOrb()
                .padding(.trailing, 14)
                .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.8)) {
                treeGrowth = 1.0
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("M I L L I")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(2)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(MilliColors.cyan)
                }
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, MilliLayout.lg)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tree of Life")
                    .font(MilliFont.heroNumber)
                    .foregroundStyle(.white)
                Text("Your financial journey, past and future.")
                    .font(MilliFont.body)
                    .foregroundStyle(MilliColors.textSecondary)
            }
            .padding(.horizontal, MilliLayout.screenMargin)
            .padding(.top, MilliSpacing.sm)
        }
    }
    
    // MARK: - Tree Visualization
    private var treeVisualization: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [MilliColors.cyan.opacity(0.06), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
            
            Canvas { context, size in
                let midX = size.width / 2
                let baseY = size.height - 16
                let growthFactor = treeGrowth
                
                // Roots (past — below ground)
                let rootColor = Color(hex: "00E5FF").opacity(0.3 * Double(growthFactor))
                let roots: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (midX, baseY, midX - 30, baseY + 10),
                    (midX, baseY, midX + 30, baseY + 10),
                    (midX - 15, baseY + 5, midX - 40, baseY + 15),
                    (midX + 15, baseY + 5, midX + 40, baseY + 15),
                ]
                for r in roots {
                    var path = Path()
                    path.move(to: CGPoint(x: r.0, y: r.1))
                    path.addLine(to: CGPoint(x: r.2, y: r.3))
                    context.stroke(path, with: .color(rootColor), lineWidth: 1.5)
                }
                
                // Trunk (present)
                let trunkTop = baseY - (100 * growthFactor)
                var trunk = Path()
                trunk.move(to: CGPoint(x: midX, y: baseY))
                trunk.addLine(to: CGPoint(x: midX, y: trunkTop))
                context.stroke(trunk, with: .color(Color(hex: "00E5FF").opacity(0.8)), lineWidth: 3)
                
                // Branches (future)
                if growthFactor > 0.3 {
                    let branchOpacity = min(1.0, (Double(growthFactor) - 0.3) * 1.5)
                    let branchColor = Color(hex: "00E5FF").opacity(0.6 * branchOpacity)
                    
                    let branches: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                        (midX, trunkTop + 30, midX - 35, trunkTop + 10),
                        (midX, trunkTop + 30, midX + 35, trunkTop + 10),
                        (midX, trunkTop + 15, midX - 25, trunkTop - 10),
                        (midX, trunkTop + 15, midX + 25, trunkTop - 10),
                        (midX, trunkTop, midX - 15, trunkTop - 20),
                        (midX, trunkTop, midX + 15, trunkTop - 20),
                        (midX - 35, trunkTop + 10, midX - 50, trunkTop - 5),
                        (midX + 35, trunkTop + 10, midX + 50, trunkTop - 5),
                    ]
                    
                    for b in branches {
                        var path = Path()
                        path.move(to: CGPoint(x: b.0, y: b.1))
                        path.addLine(to: CGPoint(x: b.2, y: b.3))
                        context.stroke(path, with: .color(branchColor), lineWidth: 1.5)
                    }
                    
                    // Leaf nodes (future goals)
                    let leaves: [(CGFloat, CGFloat)] = [
                        (midX - 50, trunkTop - 5),
                        (midX + 50, trunkTop - 5),
                        (midX - 15, trunkTop - 20),
                        (midX + 15, trunkTop - 20),
                        (midX - 25, trunkTop - 10),
                        (midX + 25, trunkTop - 10),
                    ]
                    for leaf in leaves {
                        let rect = CGRect(x: leaf.0 - 4, y: leaf.1 - 4, width: 8, height: 8)
                        context.fill(Path(ellipseIn: rect), with: .color(Color(hex: "00E5FF").opacity(0.7 * branchOpacity)))
                    }
                }
                
                // Center "now" indicator
                let nowY = trunkTop + 50
                let nowRect = CGRect(x: midX - 5, y: nowY - 5, width: 10, height: 10)
                context.fill(Path(ellipseIn: nowRect), with: .color(Color(hex: "00E5FF")))
            }
            .frame(width: 200, height: 180)
            
            // "NOW" label
            VStack {
                Spacer()
                Text("NOW")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(MilliColors.cyan)
                    .tracking(1.5)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(MilliColors.cyan.opacity(0.12))
                            .overlay(Capsule().stroke(MilliColors.cyan.opacity(0.3), lineWidth: 0.5))
                    )
                    .offset(y: -50)
            }
            .frame(width: 200, height: 180)
        }
        .frame(height: 200)
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    // MARK: - Filter Row
    private var filterRow: some View {
        HStack(spacing: MilliSpacing.sm) {
            ForEach(TreeFilter.allCases, id: \.self) { filter in
                Button(action: { withAnimation(.easeOut(duration: 0.2)) { selectedFilter = filter } }) {
                    Text(filter.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(selectedFilter == filter ? .white : MilliColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? MilliColors.cyan.opacity(0.15) : Color.clear)
                                .overlay(
                                    Capsule()
                                        .stroke(selectedFilter == filter ? MilliColors.cyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    // MARK: - Timeline Section
    private var timelineSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                timelineRow(event: event, isLast: index == filteredEvents.count - 1)
            }
        }
        .padding(.horizontal, MilliLayout.screenMargin)
    }
    
    private func timelineRow(event: LifeEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline connector
            VStack(spacing: 0) {
                // Node dot
                ZStack {
                    Circle()
                        .fill(event.isMilestone ? MilliColors.cyan : MilliColors.cyan.opacity(0.3))
                        .frame(width: event.isMilestone ? 12 : 8, height: event.isMilestone ? 12 : 8)
                    if event.isMilestone {
                        Circle()
                            .fill(MilliColors.cyan.opacity(0.2))
                            .frame(width: 20, height: 20)
                    }
                }
                .frame(width: 20, height: 20)
                
                // Connector line
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [MilliColors.cyan.opacity(0.3), MilliColors.cyan.opacity(0.1)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 20)
            
            // Event card
            VStack(alignment: .leading, spacing: MilliSpacing.xs) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(event.isPast ? MilliColors.cyan.opacity(0.08) : MilliColors.cyan.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: event.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(event.isPast ? MilliColors.cyan.opacity(0.7) : MilliColors.cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(event.subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(MilliColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(event.date)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(MilliColors.textMuted)
                        if let amount = event.amount {
                            Text(amount)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MilliColors.cyan.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.horizontal, MilliLayout.cardPaddingH)
            .padding(.vertical, MilliLayout.cardPaddingV)
            .milliSurface()
            .padding(.bottom, MilliSpacing.md)
        }
    }
}

#Preview {
    TreeOfLifeView()
}
