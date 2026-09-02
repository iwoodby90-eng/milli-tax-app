import SwiftUI

// MARK: - HeroMetricCard
// One parameterized hero component for every primary financial figure:
// Available to Spend (08), Tax Vault reserve (10), net worth (17), account
// value (18), retirement balance (19), projected net worth (20), mileage
// annual total (11), expense total (15), offer amount (14).
// ChromeHeroCard base; provenance tag is mandatory (data truth, Section 07).

struct HeroMetricCard: View {
    enum MetricKind {
        case spendable      // Available to Spend
        case reserve        // Tax Vault reserve
        case netWorth
        case accountValue
        case projected      // projections must read as ESTIMATED
        case annualTotal

        var label: String {
            switch self {
            case .spendable: return "AVAILABLE TO SPEND"
            case .reserve: return "TAX VAULT RESERVE"
            case .netWorth: return "TOTAL WEALTH"
            case .accountValue: return "TOTAL ACCOUNT VALUE"
            case .projected: return "PROJECTED NET WORTH"
            case .annualTotal: return "THIS YEAR"
            }
        }
    }

    let kind: MetricKind
    let value: String
    let provenance: ProvenanceState
    var caption: String?
    var action: (() -> Void)?

    var body: some View {
        Group {
            if let action {
                Button(action: action) { inner }
                    .buttonStyle(.plain)
            } else {
                inner
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.label), \(value), \(provenance.accessibilityLabel)")
    }

    private var inner: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(kind.label)
                    .font(MilliFont.sectionLabel)
                    .tracking(0.9)
                    .foregroundStyle(MilliColors.textSecondary)
                Spacer(minLength: 0)
                ProvenanceTag(state: provenance)
            }

            Text(value)
                .font(MilliFont.heroBalance)
                .monospacedDigit()
                .foregroundStyle(MilliColors.textPrimary)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            if let caption {
                Text(caption)
                    .font(MilliFont.caption)
                    .foregroundStyle(MilliColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .chromeHeroCard()
    }
}