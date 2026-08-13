import SwiftUI

struct RetirementView: View {
    @State private var balanceVisible = true
    @State private var projectionRange = "10 Years"
    @State private var viewByFuture = true
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // MARK: Header
                    headerSection
                    
                    // MARK: Hero Card
                    heroCard
                    
                    // MARK: Controls
                    controlsRow
                    
                    // MARK: Chart
                    chartCard
                    
                    // MARK: Three-column stats
                    threeColumnRow
                    
                    // MARK: Est Monthly Income
                    monthlyIncomeCard
                    
                    // MARK: Scenario Comparison
                    scenarioSection
                    
                    Spacer().frame(height: 100)
                }
            }
            
            MilliAICompanion()
        }
        .background(Color(hex: "07090B").ignoresSafeArea())
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("milli")
                    .font(.system(size: 22, weight: .bold))
                    .italic()
                    .foregroundStyle(Color(hex: "00E5FF"))
                    .tracking(1)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                    Circle()
                        .fill(Color(hex: "00E5FF"))
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
            
            Text("Retirement")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Plan today. Prosper tomorrow.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .padding(.horizontal, MilliSpacing.xl)
        .padding(.top, MilliSpacing.lg)
    }
    
    // MARK: - Hero Card
    private var heroCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack(spacing: 6) {
                    Text("Projected Balance")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Button(action: { balanceVisible.toggle() }) {
                        Image(systemName: balanceVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "8E92A0"))
                    }
                }
                
                Text(balanceVisible ? "$2,652,113" : "••••••")
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.white)
                
                Text("at age 65")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "00E5FF"))
                    Text("+$1,240,093 (88%) more than today")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
            }
            
            Spacer()
            
            // Glowing tree of life
            treeOfLifeView
        }
        .padding(MilliSpacing.xl)
        .frame(minHeight: 200)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private var treeOfLifeView: some View {
        ZStack {
            // Base platform
            VStack(spacing: 0) {
                Spacer()
                Ellipse()
                    .fill(Color(hex: "1A1F2E"))
                    .frame(width: 60, height: 12)
                Rectangle()
                    .fill(Color(hex: "1A1F2E"))
                    .frame(width: 40, height: 8)
                    .offset(y: -4)
            }
            .frame(width: 120, height: 140)
            
            // Tree
            Canvas { context, size in
                let midX = size.width / 2
                let baseY = size.height - 24
                
                // Trunk
                var trunk = Path()
                trunk.move(to: CGPoint(x: midX, y: baseY))
                trunk.addLine(to: CGPoint(x: midX, y: baseY - 60))
                context.stroke(trunk, with: .color(Color(hex: "00E5FF").opacity(0.8)), lineWidth: 2)
                
                // Branches
                let branches: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
                    (midX, baseY - 40, midX - 25, baseY - 65),
                    (midX, baseY - 40, midX + 25, baseY - 65),
                    (midX, baseY - 55, midX - 18, baseY - 80),
                    (midX, baseY - 55, midX + 18, baseY - 80),
                    (midX, baseY - 60, midX - 30, baseY - 90),
                    (midX, baseY - 60, midX + 30, baseY - 90),
                    (midX - 25, baseY - 65, midX - 40, baseY - 85),
                    (midX + 25, baseY - 65, midX + 40, baseY - 85),
                    (midX, baseY - 60, midX, baseY - 95),
                    (midX - 18, baseY - 80, midX - 25, baseY - 100),
                    (midX + 18, baseY - 80, midX + 25, baseY - 100),
                ]
                
                for b in branches {
                    var path = Path()
                    path.move(to: CGPoint(x: b.0, y: b.1))
                    path.addLine(to: CGPoint(x: b.2, y: b.3))
                    context.stroke(path, with: .color(Color(hex: "00E5FF").opacity(0.6)), lineWidth: 1.2)
                }
                
                // Leaf dots
                let leaves: [(CGFloat, CGFloat)] = [
                    (midX - 40, baseY - 85), (midX + 40, baseY - 85),
                    (midX - 25, baseY - 100), (midX + 25, baseY - 100),
                    (midX, baseY - 95), (midX - 30, baseY - 90),
                    (midX + 30, baseY - 90),
                ]
                for leaf in leaves {
                    let rect = CGRect(x: leaf.0 - 3, y: leaf.1 - 3, width: 6, height: 6)
                    context.fill(Path(ellipseIn: rect), with: .color(Color(hex: "00E5FF").opacity(0.7)))
                }
            }
            .frame(width: 120, height: 140)
            
            // M label on base
            VStack {
                Spacer()
                Text("M")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                    .offset(y: -16)
            }
            .frame(width: 120, height: 140)
        }
        .frame(width: 120, height: 140)
    }
    
    // MARK: - Controls
    private var controlsRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text("Projection Range")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "8E92A0"))
                
                HStack(spacing: 4) {
                    Text(projectionRange)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(hex: "121620"))
                )
            }
            
            Spacer()
            
            HStack(spacing: 0) {
                Text("Future Value")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(viewByFuture ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(viewByFuture ? Color(hex: "00E5FF") : .clear, lineWidth: 1)
                    )
                    .onTapGesture { viewByFuture = true }
                
                Text("Income")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(!viewByFuture ? Color(hex: "00E5FF") : Color(hex: "8E92A0"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .stroke(!viewByFuture ? Color(hex: "00E5FF") : .clear, lineWidth: 1)
                    )
                    .onTapGesture { viewByFuture = false }
            }
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Chart
    private var chartCard: some View {
        VStack(spacing: MilliSpacing.md) {
            HStack(alignment: .top) {
                // Y-axis labels
                VStack(alignment: .trailing, spacing: 0) {
                    Text("$3M").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                    Spacer()
                    Text("$2M").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                    Spacer()
                    Text("$1M").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                    Spacer()
                    Text("$0").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                }
                .frame(width: 30, height: 160)
                
                // Chart area
                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { _ in
                            Divider().background(Color.white.opacity(0.05))
                            Spacer()
                        }
                    }
                    .frame(height: 160)
                    
                    // Chart line and fill
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        let points: [CGPoint] = [
                            CGPoint(x: 0, y: h),
                            CGPoint(x: w * 0.2, y: h * 0.85),
                            CGPoint(x: w * 0.4, y: h * 0.65),
                            CGPoint(x: w * 0.6, y: h * 0.45),
                            CGPoint(x: w * 0.8, y: h * 0.25),
                            CGPoint(x: w, y: h * 0.12)
                        ]
                        
                        // Fill
                        Path { path in
                            path.move(to: points[0])
                            for i in 1..<points.count {
                                let prev = points[i - 1]
                                let curr = points[i]
                                let midX = (prev.x + curr.x) / 2
                                path.addQuadCurve(to: curr, control: CGPoint(x: midX, y: prev.y))
                            }
                            path.addLine(to: CGPoint(x: w, y: h))
                            path.addLine(to: CGPoint(x: 0, y: h))
                            path.closeSubpath()
                        }
                        .fill(LinearGradient(
                            colors: [Color(hex: "00E5FF").opacity(0.3), Color(hex: "00E5FF").opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        
                        // Line
                        Path { path in
                            path.move(to: points[0])
                            for i in 1..<points.count {
                                let prev = points[i - 1]
                                let curr = points[i]
                                let midX = (prev.x + curr.x) / 2
                                path.addQuadCurve(to: curr, control: CGPoint(x: midX, y: prev.y))
                            }
                        }
                        .stroke(Color(hex: "00E5FF"), lineWidth: 2.5)
                        
                        // Dot markers
                        ForEach(0..<points.count, id: \.self) { i in
                            Circle()
                                .fill(Color(hex: "00E5FF"))
                                .frame(width: 6, height: 6)
                                .position(points[i])
                        }
                        
                        // End callout
                        Text("$2.65M / in 10 years")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: "1A1F2E"))
                            )
                            .position(x: w - 60, y: points.last!.y - 20)
                    }
                    .frame(height: 160)
                }
            }
            
            // X-axis labels
            HStack {
                Text("Today").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                Spacer()
                Text("2 Yrs").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                Spacer()
                Text("4 Yrs").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                Spacer()
                Text("6 Yrs").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                Spacer()
                Text("8 Yrs").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
                Spacer()
                Text("10 Yrs").font(.system(size: 11)).foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(.leading, 34)
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Three Column
    private var threeColumnRow: some View {
        HStack(spacing: MilliSpacing.sm) {
            // Your Contribution
            VStack(spacing: MilliSpacing.sm) {
                // Partial donut
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 40, height: 40)
                    Circle()
                        .trim(from: 0, to: 0.15)
                        .stroke(Color(hex: "00E5FF"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                }
                Text("15%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                Text("Your Contribution")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E92A0"))
                    .multilineTextAlignment(.center)
                Text("$1,240/mo")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(MilliSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
            
            // Employer Match
            VStack(spacing: MilliSpacing.sm) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("5%")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Employer Match")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E92A0"))
                    .multilineTextAlignment(.center)
                Text("$413/mo")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(MilliSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
            
            // Goal Progress
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                HStack {
                    Spacer()
                    Text("68%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
                ProgressView(value: 0.68)
                    .tint(Color(hex: "34C759"))
                Text("Goal Progress")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("On track for retirement")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("$1,800,000 Your Goal")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            .padding(MilliSpacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: MilliRadius.card)
                    .fill(Color(hex: "121620"))
                    .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Monthly Income
    private var monthlyIncomeCard: some View {
        HStack(spacing: MilliSpacing.lg) {
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("Est. Monthly Income")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("$10,842/mo")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("At retirement")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            
            Divider()
                .frame(height: 60)
                .background(Color.white.opacity(0.1))
            
            VStack(alignment: .leading, spacing: MilliSpacing.sm) {
                Text("Confidence Level")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("High")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                ProgressView(value: 0.85)
                    .tint(Color(hex: "34C759"))
            }
            
            // Mini AI orb
            ZStack {
                Circle()
                    .fill(Color(hex: "1A1F2E"))
                    .frame(width: 36, height: 36)
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "00E5FF")).frame(width: 4, height: 4)
                    Circle().fill(Color(hex: "00E5FF")).frame(width: 4, height: 4)
                }
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Scenarios
    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            HStack {
                Text("Scenario Comparison")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Text("View details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "00E5FF"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "00E5FF"))
                }
            }
            .padding(.horizontal, MilliSpacing.xl)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MilliSpacing.md) {
                    scenarioCard(title: "Current Plan", amount: "$2.65M", monthly: "$10,842/mo", forecast: "10 yr forecast", borderColor: Color(hex: "00E5FF"), badge: nil)
                    scenarioCard(title: "Increase to 20%", amount: "$3.35M", monthly: "$13,680/mo", forecast: "10 yr forecast", borderColor: Color.white.opacity(0.06), badge: ("arrow.up", Color(hex: "00E5FF")))
                    scenarioCard(title: "Delay 2 Years", amount: "$2.05M", monthly: "$8,420/mo", forecast: "10 yr forecast", borderColor: Color.white.opacity(0.06), badge: ("arrow.down", Color(hex: "FF3B30")))
                }
                .padding(.horizontal, MilliSpacing.xl)
            }
        }
    }
    
    private func scenarioCard(title: String, amount: String, monthly: String, forecast: String, borderColor: Color, badge: (String, Color)?) -> some View {
        VStack(alignment: .leading, spacing: MilliSpacing.sm) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let badge = badge {
                    Image(systemName: badge.0)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(badge.1)
                        .padding(4)
                        .background(Circle().fill(badge.1.opacity(0.15)))
                }
            }
            
            Text(amount)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
            
            Text(monthly)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: "00E5FF"))
            
            Text(forecast)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "8E92A0"))
            
            // Mini sparkline
            miniSparkline
        }
        .padding(MilliSpacing.lg)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(borderColor, lineWidth: 1))
        )
    }
    
    private var miniSparkline: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let points: [CGPoint] = [
                CGPoint(x: 0, y: h * 0.8),
                CGPoint(x: w * 0.25, y: h * 0.6),
                CGPoint(x: w * 0.5, y: h * 0.45),
                CGPoint(x: w * 0.75, y: h * 0.3),
                CGPoint(x: w, y: h * 0.15)
            ]
            var path = Path()
            path.move(to: points[0])
            for p in points.dropFirst() {
                path.addLine(to: p)
            }
            context.stroke(path, with: .color(Color(hex: "00E5FF")), lineWidth: 1.5)
        }
        .frame(height: 24)
    }
}

#Preview {
    RetirementView()
}
