import SwiftUI

/// Blueprint v2 §5–§6 — Premium financial ledger and transaction state badges.
/// Visual layer only: state semantics are owned by Sun/Matteo and are NOT redefined here.

/// §6 — Transaction state badge treatments.
/// Pill: 4/8pt padding, 8pt radius, 1pt border at 30% status color, Carbon fill 70%, 6pt dot.
/// Status is never communicated by color alone: icon + text always present.
struct MilliTransactionStateBadge: View {

    enum TransactionState: String, CaseIterable {
        case requested = "REQUESTED"
        case processing = "PROCESSING"
        case posted = "POSTED"
        case failed = "FAILED"
        case reversed = "REVERSED"
        case cancelled = "CANCELLED"

        var color: Color {
            switch self {
            case .requested, .cancelled: return MilliBlueprint.Palette.polishedSilver
            case .processing: return MilliBlueprint.Palette.warning
            case .posted: return MilliBlueprint.Palette.positive
            case .failed, .reversed: return MilliBlueprint.Palette.negative
            }
        }

        var systemImage: String {
            switch self {
            case .requested: return "clock"
            case .processing: return "arrow.triangle.2.circlepath"
            case .posted: return "checkmark.circle"
            case .failed: return "xmark.circle"
            case .reversed: return "arrow.uturn.left"
            case .cancelled: return "prohibit"
            }
        }

        var strikethrough: Bool { self == .cancelled }
    }

    let state: TransactionState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: state.systemImage)
                .font(.system(size: 10))
                .rotationEffect(.degrees(state == .processing && !reduceMotion ? 360 : 0))
                .animation(
                    state == .processing && !reduceMotion
                        ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                        : .default,
                    value: state
                )
            Text(state.rawValue)
                .font(MilliBlueprint.Type.inter(10))
                .tracking(0.5)
                .strikethrough(state.strikethrough)
        }
        .foregroundStyle(state.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(MilliBlueprint.Palette.carbon.opacity(0.7)))
        .overlay(Capsule().strokeBorder(state.color.opacity(0.3), lineWidth: 1))
        .accessibilityLabel(state.rawValue.lowercased())
    }
}

/// §5 — Ledger row anatomy.
/// Left → right: category icon · identifier + date/time · amount + status badge ·
/// receipt reference · running balance. 64pt height, 1pt Carbon dividers, no row borders.
struct MilliLedgerRow: View {

    struct Model {
        let identifier: String
        let dateTime: String
        let amountText: String
        let isCredit: Bool
        let state: MilliTransactionStateBadge.TransactionState
        let receiptRef: String?
        let runningBalanceText: String?
        let reversalLink: String?
        let categorySystemImage: String
    }

    let model: Model

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: MilliBlueprint.Space.m) {
                Image(systemName: model.categorySystemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.identifier)
                        .font(MilliBlueprint.Type.inter(13, weight: .medium))
                        .foregroundStyle(MilliBlueprint.Palette.white)
                    Text(model.dateTime)
                        .font(MilliBlueprint.Type.inter(11))
                        .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(model.amountText)
                        .font(MilliBlueprint.Type.monetary(14))
                        .foregroundStyle(model.isCredit ? MilliBlueprint.Palette.positive : MilliBlueprint.Palette.negative)
                    MilliTransactionStateBadge(state: model.state)
                }
                VStack(alignment: .trailing, spacing: 2) {
                    if let ref = model.receiptRef {
                        Text(ref)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                    }
                    if let bal = model.runningBalanceText {
                        Text(bal)
                            .font(MilliBlueprint.Type.monetary(11))
                            .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                    }
                }
            }
            .padding(.horizontal, MilliBlueprint.Space.l)
            .frame(minHeight: 64)
            if let reversal = model.reversalLink {
                Text("↺ Reversed by \(reversal)")
                    .font(MilliBlueprint.Type.inter(10))
                    .foregroundStyle(MilliBlueprint.Palette.negative)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, MilliBlueprint.Space.l)
                    .padding(.bottom, MilliBlueprint.Space.s)
            }
            Divider()
                .overlay(MilliBlueprint.Palette.carbon)
        }
        .background(.thinMaterial)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(model.identifier), \(model.amountText), \(model.state.rawValue.lowercased()), \(model.dateTime)")
    }
}

/// §5 — Ledger container: Carbon card, .thinMaterial, 18pt radius, silver border 6%.
/// Empty data is never fabricated: a single "No transactions yet" row appears instead.
struct MilliLedgerCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(MilliBlueprint.Palette.carbon)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(MilliBlueprint.Palette.polishedSilver.opacity(0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview("Ledger") {
    MilliLedgerCard {
        MilliLedgerRow(model: .init(
            identifier: "DoorDash payout protection",
            dateTime: "Aug 26 · 2:43 PM",
            amountText: "+$24.62",
            isCredit: true,
            state: .posted,
            receiptRef: "AP-2026-000025",
            runningBalanceText: "Bal $5,284.17",
            reversalLink: nil,
            categorySystemImage: "storefront"
        ))
        MilliLedgerRow(model: .init(
            identifier: "Uber payout protection",
            dateTime: "Aug 25 · 9:12 PM",
            amountText: "+$18.40",
            isCredit: true,
            state: .processing,
            receiptRef: nil,
            runningBalanceText: nil,
            reversalLink: nil,
            categorySystemImage: "car"
        ))
    }
    .padding(20)
    .background(MilliBlueprint.Palette.obsidian)
    .preferredColorScheme(.dark)
}
