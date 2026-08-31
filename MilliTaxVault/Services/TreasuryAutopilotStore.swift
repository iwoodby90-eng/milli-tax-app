import SwiftUI

// MARK: - TreasuryAutopilotStore
// Read-only projection of backend/provider state for the Stripe Treasury
// Autopilot UI. This store NEVER fabricates financial data: with no backend
// connected it reports an empty, honestly-labeled state. Demo content exists
// only behind the explicit demo provider and is visibly labeled DEMO.

import Combine

@MainActor
public final class TreasuryAutopilotStore: ObservableObject {
    @Published public private(set) var payouts: [AutopilotPayout] = []
    @Published public private(set) var accountStatus: FinancialAccountStatus = .notOpened
    @Published public private(set) var autopilot: AutopilotConfiguration = AutopilotConfiguration()
    @Published public private(set) var provenance: ProvenanceLabel = .unavailable
    @Published public private(set) var lastSyncedAt: Date?

    /// Demo provider — the ONLY source of non-authoritative content.
    /// All demo payouts carry provenance .demo and are visibly labeled.
    public func loadDemoData() {
        payouts = [
            AutopilotPayout(id: "demo-1", platform: "DoorDash", grossAmountCents: 31245, state: .allocated, provenance: .demo),
            AutopilotPayout(id: "demo-2", platform: "Uber", grossAmountCents: 21264, state: .processing, provenance: .demo),
            AutopilotPayout(id: "demo-3", platform: "Spark", grossAmountCents: 18420, state: .detected, provenance: .demo),
            AutopilotPayout(id: "demo-4", platform: "Instacart", grossAmountCents: 7820, state: .failed, provenance: .demo)
        ]
        accountStatus = .active
        autopilot = AutopilotConfiguration(isEnabled: true, estimatedTaxRateBps: 3000)
        provenance = .demo
        lastSyncedAt = Date()
    }

    /// Production path: ingest authoritative backend payloads only.
    public func ingest(payouts: [AutopilotPayout], accountStatus: FinancialAccountStatus, autopilot: AutopilotConfiguration) {
        self.payouts = payouts
        self.accountStatus = accountStatus
        self.autopilot = autopilot
        self.provenance = .live
        self.lastSyncedAt = Date()
    }

    /// Honest empty state: no backend, no fabricated balances.
    public func markUnavailable() {
        payouts = []
        accountStatus = .unavailable
        provenance = .unavailable
        lastSyncedAt = nil
    }
}
