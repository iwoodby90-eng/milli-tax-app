import SwiftUI

/// Blueprint v2 §7–§9 — Transaction detail sheet, action area, and state views.
/// Visual layer only; failure/reversal sections appear only when relevant — never empty.

// MARK: - §7 Transaction Detail Sheet (premium banking receipt)

struct MilliTransactionDetailSheet: View {

    struct Model {
        let amountText: String
        let isCredit: Bool
        let state: MilliTransactionStateBadge.TransactionState
        let source: String
        let destination: String
        let dateTimePosted: String
        let transactionID: String
        let providerRef: String?
        let failureReason: String?
        let reversalInfo: String?
    }

    let model: Model
    var onOpenReceipt: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: MilliBlueprint.Space.l) {
            Capsule()
                .fill(MilliBlueprint.Palette.polishedSilver.opacity(0.3))
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, MilliBlueprint.Space.s)
            HStack(alignment: .firstTextBaseline, spacing: MilliBlueprint.Space.m) {
                Text(model.amountText)
                    .font(MilliBlueprint.Type.monetary(28, sora: true))
                    .foregroundStyle(model.isCredit ? MilliBlueprint.Palette.positive : MilliBlueprint.Palette.negative)
                MilliTransactionStateBadge(state: model.state)
            }
            detailRow(label: "SOURCE → DESTINATION") {
                HStack(spacing: MilliBlueprint.Space.xs) {
                    Text(model.source).foregroundStyle(MilliBlueprint.Palette.white)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                    Text(model.destination).foregroundStyle(MilliBlueprint.Palette.white)
                }
            }
            detailRow(label: "DATE / TIME POSTED") {
                Text(model.dateTimePosted).foregroundStyle(MilliBlueprint.Palette.white)
            }
            detailRow(label: "TRANSACTION ID") {
                Text(model.transactionID)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
            }
            if let provider = model.providerRef {
                detailRow(label: "PROVIDER REFERENCE") {
                    Text(provider)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                }
            }
            Button {
                onOpenReceipt?()
            } label: {
                HStack(spacing: MilliBlueprint.Space.xs) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 16))
                    Text("Financial Receipt")
                        .font(MilliBlueprint.Type.inter(14, weight: .medium))
                }
                .foregroundStyle(MilliBlueprint.Palette.electricCyan)
            }
            .accessibilityLabel("Financial Receipt, opens receipt")
            if let failure = model.failureReason {
                detailRow(label: "FAILURE REASON") {
                    Text(failure).foregroundStyle(MilliBlueprint.Palette.negative)
                }
            }
            if let reversal = model.reversalInfo {
                detailRow(label: "RETURN / REVERSAL") {
                    Text(reversal).foregroundStyle(MilliBlueprint.Palette.negative)
                }
            }
            Spacer()
        }
        .font(MilliBlueprint.Type.inter(14))
        .padding(MilliBlueprint.Space.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous)
                .fill(MilliBlueprint.Palette.carbon)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous))
        )
        .overlay(alignment: .top) {
            // Cyan top-edge light, 5%, 20pt blur.
            RoundedRectangle(cornerRadius: MilliBlueprint.Radius.hero, style: .continuous)
                .fill(MilliBlueprint.Palette.electricCyan.opacity(0.05))
                .frame(height: 20)
                .blur(radius: 10)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func detailRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(MilliBlueprint.Type.inter(11))
                .tracking(1)
                .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
            content()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - §8 Action Area

struct MilliPrimaryAction: View {
    let title: String
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: MilliBlueprint.Space.xs) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(MilliBlueprint.Palette.electricCyan)
                Text(title)
                    .font(MilliBlueprint.Type.inter(14, weight: .medium))
                    .foregroundStyle(MilliBlueprint.Palette.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Capsule().fill(MilliBlueprint.Palette.electricCyan.opacity(0.18))
            )
            .overlay(Capsule().strokeBorder(MilliBlueprint.Palette.electricCyan, lineWidth: 1))
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(PressScaleStyle(onChange: { pressed = $0 }))
        .accessibilityLabel("\(title), button")
    }
}

struct MilliSecondaryAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MilliBlueprint.Space.xs) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                Text(title)
                    .font(MilliBlueprint.Type.inter(14, weight: .medium))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
        }
        .accessibilityLabel("\(title), button")
    }
}

private struct PressScaleStyle: ButtonStyle {
    var onChange: (Bool) -> Void
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { onChange($0) }
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - §9 Empty / Error / Unavailable / Processing / Failed / Reversed states

struct MilliLedgerStateView: View {

    enum Kind {
        case empty, error, unavailable, processing, failed, reversed

        var systemImage: String {
            switch self {
            case .empty: return "lock.shield"
            case .error: return "exclamationmark.circle"
            case .unavailable: return "lock"
            case .processing: return "arrow.triangle.2.circlepath"
            case .failed: return "xmark.circle"
            case .reversed: return "arrow.uturn.left"
            }
        }

        var iconColor: Color {
            switch self {
            case .empty: return MilliBlueprint.Palette.polishedSilver.opacity(0.3)
            case .error, .failed, .reversed: return MilliBlueprint.Palette.negative
            case .unavailable: return MilliBlueprint.Palette.polishedSilver.opacity(0.4)
            case .processing: return MilliBlueprint.Palette.warning
            }
        }

        var headline: String {
            switch self {
            case .empty: return "Nothing protected yet"
            case .error: return "Something went wrong"
            case .unavailable: return "Tax Vault unavailable"
            case .processing: return "Processing"
            case .failed: return "Transaction failed"
            case .reversed: return "Transaction reversed"
            }
        }

        var subtext: String {
            switch self {
            case .empty: return "When income is deposited, Tax Vault will automatically set aside funds for taxes."
            case .error: return "We couldn't load your Tax Vault. Please try again."
            case .unavailable: return "This feature is temporarily unavailable. Your funds are safe."
            case .processing: return "Your transaction is being processed. This usually takes a few moments."
            case .failed: return "This transaction could not be completed. No funds were moved."
            case .reversed: return "This transaction was reversed. Funds have been returned to their source."
            }
        }
    }

    let kind: Kind
    var actionTitle: String?
    var actionIsPrimary = false
    var action: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: MilliBlueprint.Space.xxxl) {
            ZStack {
                // 60pt radial cyan glow at 4% (disabled under Reduce Motion).
                if !reduceMotion {
                    RadialGradient(
                        colors: [MilliBlueprint.Palette.electricCyan.opacity(0.04), .clear],
                        center: .center, startRadius: 0, endRadius: 30
                    )
                    .frame(width: 60, height: 60)
                }
                Image(systemName: kind.systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(kind.iconColor)
            }
            VStack(spacing: MilliBlueprint.Space.s) {
                Text(kind.headline)
                    .font(MilliBlueprint.Type.sora(16))
                    .foregroundStyle(MilliBlueprint.Palette.white)
                Text(kind.subtext)
                    .font(MilliBlueprint.Type.inter(13))
                    .foregroundStyle(MilliBlueprint.Palette.polishedSilver)
                    .multilineTextAlignment(.center)
            }
            if let title = actionTitle {
                if actionIsPrimary {
                    MilliPrimaryAction(title: title) { action?() }
                } else {
                    MilliSecondaryAction(title: title, systemImage: "doc.text") { action?() }
                }
            }
        }
        .padding(MilliBlueprint.Space.xxl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MilliBlueprint.Palette.carbon)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(MilliBlueprint.Palette.polishedSilver.opacity(0.06), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview("States") {
    VStack(spacing: 16) {
        MilliLedgerStateView(kind: .empty, actionTitle: "Add to Tax Vault", actionIsPrimary: true)
        MilliLedgerStateView(kind: .processing)
    }
    .padding(20)
    .background(MilliBlueprint.Palette.obsidian)
    .preferredColorScheme(.dark)
}
