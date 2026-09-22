import SwiftUI
import Combine

// MARK: - HomeViewModel — Drives the Home dashboard
//
// Figures are derived by MilliFinancialSnapshot from the verified payout
// ledger and the user's own tax profile. Nothing is seeded: an account with
// no connected bank keeps every slot in its unavailable state, and the
// provenance tag states where each populated figure came from.

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var availableToSpend: String = MilliPlaceholder.value
    @Published var sparklineData: [CGFloat] = []
    @Published var latestPayout: PayoutEntry? = nil
    @Published var taxVaultBalance: String = MilliPlaceholder.value
    @Published var taxVaultProgress: CGFloat? = nil
    @Published var taxReadyScore: Int? = nil
    @Published var quarterlyTaxes: String = MilliPlaceholder.value
    @Published var quarterlyDueLabel: String = "Awaiting tax profile"
    @Published var mileage: String = MilliPlaceholder.value
    @Published var aiInsight: String = "Connect verified financial data to unlock grounded Milli AI insights."
    @Published var provenance: ProvenanceLabel = .unavailable
    @Published var isLoading: Bool = false

    init() {
        loadData()
    }

    func loadData() {
        let snapshot = MilliFinancialSnapshot.current()

        availableToSpend = MilliFigureFormat.currency(snapshot.availableToSpend)
        taxVaultBalance = MilliFigureFormat.currency(snapshot.reservedForTaxes)
        taxVaultProgress = snapshot.reserveProgress.map { CGFloat($0) }
        quarterlyTaxes = MilliFigureFormat.currency(snapshot.quarterlyLiability)
        sparklineData = Self.sparkline(from: snapshot)
        latestPayout = Self.latestPayout(from: snapshot)
        provenance = snapshot.hasPayouts ? .cachedLive : .unavailable

        if let due = snapshot.nextEstimatedPaymentDue {
            quarterlyDueLabel = "Due \(MilliFigureFormat.date(due))"
        } else {
            quarterlyDueLabel = "Awaiting tax profile"
        }

        aiInsight = Self.insight(from: snapshot)
        isLoading = false
    }

    /// Cumulative available-to-spend across the payout ledger. The chart stays
    /// empty until every payout has an authoritative backend allocation amount.
    private static func sparkline(from snapshot: MilliFinancialSnapshot) -> [CGFloat] {
        let ordered = Array(snapshot.payouts.reversed())
        guard ordered.count >= 2 else { return [] }

        let rows = ordered.compactMap { payout -> Double? in
            guard let allocatedCents = payout.stateContractProjection.taxAllocatedCents else {
                return nil
            }
            let allocated = Double(allocatedCents) / 100.0
            return payout.grossAmount - allocated
        }
        guard rows.count == ordered.count else { return [] }

        var running = 0.0
        return rows.map { spendable in
            running += spendable
            return CGFloat(running)
        }
    }

    private static func latestPayout(from snapshot: MilliFinancialSnapshot) -> PayoutEntry? {
        guard let payout = snapshot.payouts.first else { return nil }
        return PayoutEntry(
            platformName: payout.platform,
            platformAssetName: payout.assetName ?? "MilliMLogo",
            dateTime: payout.dateLabel,
            amount: payout.grossAmount.formatted(.currency(code: "USD")),
            provenance: .cachedLive
        )
    }

    private static func insight(from snapshot: MilliFinancialSnapshot) -> String {
        guard snapshot.hasPayouts else {
            return "Connect verified financial data to unlock grounded Milli AI insights."
        }
        guard let progress = snapshot.reserveProgress else {
            return "Add your tax profile so Milli can pace your reserve against a real liability."
        }
        return progress >= snapshot.yearProgress
            ? "Your tax reserve is ahead of the calendar year. Keep the current rate."
            : "Your reserve is behind the year's pace. Raising your reserve rate closes the gap."
    }
}

// MARK: - PayoutEntry

struct PayoutEntry: Identifiable {
    let id = UUID()
    let platformName: String
    let platformAssetName: String
    let dateTime: String
    let amount: String
    let provenance: ProvenanceLabel
}
