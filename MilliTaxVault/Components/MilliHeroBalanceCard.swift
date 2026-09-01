import SwiftUI

/// Blueprint v2 §2 — Hero Balance Card "Protected for Taxes".
/// Black-glass card: protected balance, provenance badge, annual tax context.
/// Carbon surface, .regularMaterial, 24pt radius, silver border 12%,
/// cyan ambient radial illumination top-center, 1pt inner white stroke 4%.
struct MilliHeroBalanceCard: View {

    let balanceText: String
    let provenance: MilliProvenanceBadge.State
    let annualContext: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous)
                .fill(MilliBlueprint.Palette.carbon)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous))
            // Ambient cyan illumination — 120pt radial, 6% opacity, top-center.
            RadialGradient(
                colors: [MilliBlueprint.Palette.electricCyan.opacity(0.06), .clear],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 60
            )
            .frame(height: 120)
            .blur(radius: 20)
            .clipShape(RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous))
            VStack(alignment: .leading, spacing: MilliBlueprint.Space.s) {
                Text("PROTECTED FOR TAXES")
                    .font(MilliBlueprint.Type.inter(12))
                    .tracking(1)
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                Text(balanceText)
                    .font(MilliBlueprint.Type.monetary(40, sora: true))
                    .foregroundStyle(MilliBlueprint.Palette.white)
                MilliProvenanceBadge(state: provenance)
                Text(annualContext)
                    .font(MilliBlueprint.Type.inter(11))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MilliBlueprint.Space.xxl)
        }
        .overlay(
            // Polished edge: 1pt inner stroke, white 4%.
            RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous)
                .strokeBorder(MilliBlueprint.Palette.white.opacity(0.04), lineWidth: 1)
        )
        .overlay(
            // 1pt polished-silver border at 12%.
            RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous)
                .strokeBorder(MilliBlueprint.Palette.polishedSilver.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Protected for Taxes, \(balanceText), \(provenance.accessibilityLabel), \(annualContext)")
    }
}

/// Blueprint v2 §2 — Provenance badge states.
struct MilliProvenanceBadge: View {

    enum State {
        case live
        case cachedLive
        case estimated
        case userEntered
        case demo
        case preview
        case unavailable

        var label: String {
            switch self {
            case .live: return "LIVE"
            case .cachedLive: return "CACHED LIVE"
            case .estimated: return "ESTIMATED"
            case .userEntered: return "USER ENTERED"
            case .demo: return "DEMO"
            case .preview: return "PREVIEW"
            case .unavailable: return "UNAVAILABLE"
            }
        }

        var dotColor: Color {
            switch self {
            case .live: return MilliBlueprint.Palette.electricCyan
            case .cachedLive: return MilliBlueprint.Palette.electricCyan.opacity(0.5)
            case .estimated: return MilliBlueprint.Palette.polishedSilver
            case .userEntered: return MilliBlueprint.Palette.polishedSilver
            case .demo: return MilliBlueprint.Palette.polishedSilver
            case .preview: return MilliBlueprint.Palette.warning
            case .unavailable: return MilliBlueprint.Palette.negative
            }
        }

        var dashedRing: Bool { self == .userEntered }
        var hollowDot: Bool { self == .unavailable }
        var accessibilityLabel: String { label.lowercased() }
    }

    let state: State

    var body: some View {
        HStack(spacing: MilliBlueprint.Space.xs + 2) {
            Circle()
                .strokeBorder(state.hollowDot ? state.dotColor : .clear, lineWidth: 1)
                .background(Circle().fill(state.hollowDot ? .clear : state.dotColor))
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .strokeBorder(state.dotColor, style: StrokeStyle(lineWidth: 1, dash: state.dashedRing ? [2, 2] : []))
                        .frame(width: 10, height: 10)
                        .opacity(state.dashedRing ? 1 : 0)
                )
            Text(state.label)
                .font(MilliBlueprint.Type.inter(10))
                .tracking(1.5)
                .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(MilliBlueprint.Palette.carbon.opacity(0.8))
        )
        .overlay(
            Capsule().strokeBorder(state.dotColor.opacity(0.3), lineWidth: 1)
        )
        .accessibilityLabel(state.accessibilityLabel)
    }
}

#Preview("Hero — light & dark") {
    VStack(spacing: 24) {
        MilliHeroBalanceCard(
            balanceText: "$5,284.17",
            provenance: .live,
            annualContext: "23% of projected annual taxes protected"
        )
        MilliHeroBalanceCard(
            balanceText: "$5,284.17",
            provenance: .preview,
            annualContext: "Example data"
        )
    }
    .padding(20)
    .background(MilliBlueprint.Palette.obsidian)
    .preferredColorScheme(.dark)
}
