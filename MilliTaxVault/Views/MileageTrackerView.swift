import SwiftUI

struct MileageTrackerView: View {
    @State private var isTracking = true
    
    var body: some View {
        ScrollView(showsIndicators: false) {
                VStack(spacing: MilliSpacing.xl) {
                    // MARK: Header
                    headerSection
                    
                    // MARK: Live Trip
                    liveTripCard
                    
                    // MARK: Map
                    mapCard
                    
                    // MARK: Trip History
                    tripHistorySection
                    
                    // MARK: Monthly Summary
                    monthlySummaryCard
                    
                    Spacer().frame(height: 100)
                }
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
                
                // Auto-tracking badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "00E5FF"))
                        .frame(width: 8, height: 8)
                    Text("Auto-Tracking ON")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: "121620")))
                
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .padding(.leading, 8)
            }
            
            Text("Mileage Tracker")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text("Track. Save. Deduct.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .padding(.horizontal, MilliSpacing.xl)
        .padding(.top, MilliSpacing.lg)
    }
    
    // MARK: - Live Trip Card
    private var liveTripCard: some View {
        VStack(spacing: MilliSpacing.lg) {
            HStack {
                // LIVE badge
                Text("LIVE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(hex: "00E5FF")))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tracking Trip")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("Uber · Passenger")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Three stat columns
            HStack(spacing: 0) {
                statColumn(value: "12.4", unit: "Miles")
                Divider().frame(height: 40).background(Color.white.opacity(0.1))
                statColumn(value: "27m", unit: "Time")
                Divider().frame(height: 40).background(Color.white.opacity(0.1))
                HStack(spacing: 2) {
                    statColumn(value: "$8.05", unit: "Est. Deduction")
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
            }
            
            // Stop button
            Button(action: { isTracking = false }) {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                    Text("Stop Tracking")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: MilliRadius.medium)
                        .fill(Color(hex: "121620"))
                        .overlay(RoundedRectangle(cornerRadius: MilliRadius.medium).stroke(Color(hex: "00E5FF"), lineWidth: 1))
                )
            }
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(
                    RoundedRectangle(cornerRadius: MilliRadius.card)
                        .stroke(Color(hex: "00E5FF").opacity(0.4), lineWidth: 1)
                )
                .shadow(color: Color(hex: "00E5FF").opacity(0.1), radius: 12)
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func statColumn(value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(unit)
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "8E92A0"))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Map Card
    private var mapCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Dark map background
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "0D1117"))
                .frame(height: 240)
                .overlay(
                    // Grid lines
                    Canvas { context, size in
                        let spacing: CGFloat = 30
                        for i in stride(from: 0, to: size.width, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: i, y: 0))
                            path.addLine(to: CGPoint(x: i, y: size.height))
                            context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 0.5)
                        }
                        for i in stride(from: 0, to: size.height, by: spacing) {
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: i))
                            path.addLine(to: CGPoint(x: size.width, y: i))
                            context.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 0.5)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: MilliRadius.card))
                )
                .overlay(
                    // Street labels
                    ZStack {
                        Text("Wilshire Blvd")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "8E92A0").opacity(0.6))
                            .position(x: 80, y: 100)
                        Text("Beverly Hills")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "8E92A0").opacity(0.6))
                            .position(x: 200, y: 60)
                        Text("Santa Monica Blvd")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "8E92A0").opacity(0.6))
                            .position(x: 150, y: 160)
                    }
                )
                .overlay(
                    // Route line
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height
                        Path { path in
                            path.move(to: CGPoint(x: w * 0.15, y: h * 0.7))
                            path.addCurve(
                                to: CGPoint(x: w * 0.45, y: h * 0.4),
                                control1: CGPoint(x: w * 0.25, y: h * 0.6),
                                control2: CGPoint(x: w * 0.35, y: h * 0.35)
                            )
                            path.addCurve(
                                to: CGPoint(x: w * 0.75, y: h * 0.35),
                                control1: CGPoint(x: w * 0.55, y: h * 0.45),
                                control2: CGPoint(x: w * 0.65, y: h * 0.3)
                            )
                            path.addCurve(
                                to: CGPoint(x: w * 0.85, y: h * 0.25),
                                control1: CGPoint(x: w * 0.8, y: h * 0.38),
                                control2: CGPoint(x: w * 0.82, y: h * 0.28)
                            )
                        }
                        .stroke(Color(hex: "00E5FF"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        // Start point
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                            .position(x: w * 0.15, y: h * 0.7)
                        
                        // End point
                        Circle()
                            .fill(Color(hex: "00E5FF"))
                            .frame(width: 12, height: 12)
                            .position(x: w * 0.85, y: h * 0.25)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: MilliRadius.card))
                )
            
            // Overlay card
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY'S MILES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("45.7")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(hex: "00E5FF"))
                Text("EST. DEDUCTION")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Color(hex: "8E92A0"))
                Text("$29.71")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "121620").opacity(0.95))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
            )
            .padding(16)
        }
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    // MARK: - Trip History
    private var tripHistorySection: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            HStack {
                Text("Trip History")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("View all")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            
            tripRow(initial: "U", bgColor: .black, platform: "Uber", type: "Passenger", time: "8:42 AM", miles: "12.4 mi", duration: "27m", deduction: "$8.05")
            tripRow(initial: "D", bgColor: Color(hex: "FF3B30"), platform: "DoorDash", type: "Delivery", time: "7:15 AM", miles: "5.2 mi", duration: "18m", deduction: "$3.38")
            tripRow(initial: "S", bgColor: Color.blue, platform: "Spark", type: "Delivery", time: "6:30 AM", miles: "8.7 mi", duration: "22m", deduction: "$5.69")
        }
        .padding(MilliSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: MilliRadius.card)
                .fill(Color(hex: "121620"))
                .overlay(RoundedRectangle(cornerRadius: MilliRadius.card).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
        .padding(.horizontal, MilliSpacing.xl)
    }
    
    private func tripRow(initial: String, bgColor: Color, platform: String, type: String, time: String, miles: String, duration: String, deduction: String) -> some View {
        HStack(spacing: MilliSpacing.md) {
            // Platform icon
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Text(initial)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(platform) · \(type)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(time)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "8E92A0"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 8) {
                    Text(miles)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "8E92A0"))
                    Text(duration)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
                HStack(spacing: 4) {
                    Text(deduction)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8E92A0"))
                }
            }
        }
        .padding(.vertical, MilliSpacing.sm)
    }
    
    // MARK: - Monthly Summary
    private var monthlySummaryCard: some View {
        VStack(alignment: .leading, spacing: MilliSpacing.md) {
            HStack {
                Text("May 2025 Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("View all")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "00E5FF"))
            }
            
            HStack(spacing: 0) {
                summaryColumn(value: "312.8", label: "Total Miles")
                summaryColumn(value: "$203.28", label: "Est. Deduction")
                summaryColumn(value: "18", label: "Trips")
                summaryColumn(value: "12h 45m", label: "Tracked Time")
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
    
    private func summaryColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "8E92A0"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MileageTrackerView()
}
