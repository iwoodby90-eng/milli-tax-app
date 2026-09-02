import SwiftUI

// MARK: - ProgressRing (v1.2)
// One ring geometry everywhere: Tax Vault reserve (10), Tax Ready Score (08/29),
// readiness ring (28), countdown ring (19), confidence ring (21), health ring (16),
// deductible ring (15), allocation ring (17/18).
// Cyan only for selected/active intelligence state; green/red reserved for
// authoritative positive/negative states (Section 07).

struct MilliProgressRing: View {
    enum RingTone {
        case intelligence   // cyan — active/selected state
        case positive       // green — authoritative positive state
        case warning        // amber — caution state
        case negative       // red — error state

        var colors: [Color] {
            switch self {
            case .intelligence: return [MilliColors.cyanGlow, MilliColors.deepCyan]
            case .positive: return [MilliColors.positive, MilliColors.positive.opacity(0.6)]
            case .warning: return [MilliColors.warning, MilliColors.warning.opacity(0.6)]
            case .negative: return [MilliColors.negative, MilliColors.negative.opacity(0.6)]
            }
        }
    }

    let progress: Double
    var value: String?
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4
    var tone: RingTone = .intelligence
    var trackAlpha: Double = 0.09

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(trackAlpha), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(
                    LinearGradient(
                        colors: tone.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: tone.colors[0].opacity(0.35), radius: 4)
            if let value {
                Text(value)
                    .font(.custom("Sora-SemiBold", size: max(9, size * 0.27)))
                    .monospacedDigit()
                    .foregroundStyle(MilliColors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress \(Int(progress * 100)) percent\(value.map { ", \($0)" } ?? "")")
    }
}