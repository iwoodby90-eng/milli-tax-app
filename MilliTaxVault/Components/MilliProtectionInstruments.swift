import SwiftUI

/// Blueprint v2 §3 — Tax Protection Progress arc instrument.
/// 96pt outer diameter, 10pt stroke, recessed Carbon track with inner shadow,
/// Cyan→DeepCyan gradient arc with 0.5pt silver edge, 8 tick marks.
struct MilliProtectionRing: View {

    /// 0...1, clamped.
    let progress: Double
    @State private var animated: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let diameter: CGFloat = 96
    private let stroke: CGFloat = 10

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Recessed track: Carbon with 2pt inner shadow (Obsidian, 4pt blur).
                Circle()
                    .stroke(MilliBlueprint.Palette.carbon, lineWidth: stroke)
                    .overlay(
                        Circle()
                            .stroke(MilliBlueprint.Palette.obsidian.opacity(0.6), lineWidth: 2)
                            .blur(radius: 4)
                            .padding(stroke / 2)
                    )
                // Tick marks at 12.5% intervals, 4pt, Silver 20%.
                ForEach(0..<8, id: \.self) { i in
                    Rectangle()
                        .fill(MilliBlueprint.Palette.polishedSilver.opacity(0.2))
                        .frame(width: 1, height: 4)
                        .offset(y: -diameter / 2 + 2)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                // Progress arc: Cyan → Deep Cyan gradient, silver metallic edge.
                Circle()
                    .trim(from: 0, to: animated)
                    .stroke(
                        AngularGradient(
                            colors: [MilliBlueprint.Palette.electricCyan, MilliBlueprint.Palette.deepCyan],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .overlay(
                        Circle()
                            .trim(from: 0, to: animated)
                            .stroke(MilliBlueprint.Palette.polishedSilver.opacity(0.5), lineWidth: 0.5)
                            .rotationEffect(.degrees(-90))
                            .padding(1)
                    )
                    .shadow(color: MilliBlueprint.Palette.electricCyan.opacity(progress >= 0.999 ? 0.25 : 0), radius: 6)
                Text("\(Int((animated * 100).rounded()))%")
                    .font(MilliBlueprint.Type.monetary(22, sora: true))
                    .foregroundStyle(MilliBlueprint.Palette.white)
            }
            .frame(width: 128, height: 128)
            Text("of projected annual taxes protected")
                .font(MilliBlueprint.Type.inter(11))
                .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
        }
        .onAppear {
            let value = min(max(progress, 0), 1)
            if reduceMotion {
                animated = value
            } else {
                withAnimation(.easeOut(duration: MilliBlueprint.Motion.slow)) { animated = value }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Int(progress * 100)) percent of projected annual taxes protected")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}

/// Blueprint v2 §4 — Next Quarterly Obligation module.
/// Carbon surface, .regularMaterial, 18pt radius, silver border 8%, 4pt progress bar.
struct MilliQuarterlyObligationCard: View {

    let amountText: String
    let dueText: String
    let protectedText: String
    let readyPercent: Double // 0...1
    @State private var barAnimated = false

    var body: some View {
        VStack(alignment: .leading, spacing: MilliBlueprint.Space.s) {
            Text("NEXT ESTIMATED PAYMENT")
                .font(MilliBlueprint.Type.inter(11))
                .tracking(1)
                .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
            HStack(alignment: .firstTextBaseline, spacing: MilliBlueprint.Space.s) {
                Text(amountText)
                    .font(MilliBlueprint.Type.monetary(24, sora: true))
                    .foregroundStyle(MilliBlueprint.Palette.white)
                Text("ESTIMATED")
                    .font(MilliBlueprint.Type.inter(10))
                    .tracking(1)
                    .foregroundStyle(MilliBlueprint.Palette.warning)
            }
            HStack(spacing: MilliBlueprint.Space.xs) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                Text(dueText)
                    .font(MilliBlueprint.Type.inter(13))
                    .foregroundStyle(MilliBlueprint.Palette.white)
            }
            Text(protectedText)
                .font(MilliBlueprint.Type.inter(12))
                .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
            // 4pt progress bar: Carbon track, Cyan fill.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(MilliBlueprint.Palette.carbon)
                    Capsule()
                        .fill(MilliBlueprint.Palette.electricCyan)
                        .frame(width: barAnimated ? geo.size.width * min(max(readyPercent, 0), 1) : 0)
                }
            }
            .frame(height: 4)
        }
        .padding(MilliBlueprint.Space.xl)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MilliBlueprint.Palette.carbon)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MilliBlueprint.Palette.polishedSilver.opacity(0.08), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { barAnimated = true }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next estimated payment, \(amountText), \(dueText). \(protectedText). Estimated.")
    }
}

#Preview("Ring + quarterly") {
    VStack(spacing: 24) {
        MilliProtectionRing(progress: 0.23)
        MilliQuarterlyObligationCard(
            amountText: "$1,421.00",
            dueText: "Due September 15",
            protectedText: "$1,120 protected · 79% ready",
            readyPercent: 0.79
        )
    }
    .padding(20)
    .background(MilliBlueprint.Palette.obsidian)
    .preferredColorScheme(.dark)
}
