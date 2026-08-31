import XCTest
@testable import MilliTaxVault

// MARK: - TreasuryAutopilotTests
// Launch P0 evidence: state-contract invariants for the Stripe Treasury
// Autopilot UI. SwiftUI does not determine financial truth.

final class TreasuryAutopilotTests: XCTestCase {

    // MARK: Tax Vault rule

    func testTaxProtectedOnlyWhenAllocated() {
        XCTAssertEqual(PayoutState.detected.isTaxProtected, false)
        XCTAssertEqual(PayoutState.processing.isTaxProtected, false)
        XCTAssertEqual(PayoutState.failed.isTaxProtected, false)
        XCTAssertEqual(PayoutState.returned.isTaxProtected, false)
        XCTAssertEqual(PayoutState.reversed.isTaxProtected, false)
        XCTAssertEqual(PayoutState.actionRequired.isTaxProtected, false)
        XCTAssertEqual(PayoutState.unavailable.isTaxProtected, false)
        // Only the authoritative allocated state may show Tax Protected.
        XCTAssertEqual(PayoutState.allocated.isTaxProtected, true)
    }

    // MARK: Never celebrate a requested or processing transaction

    func testPositiveTreatmentOnlyWhenAllocated() {
        for state in PayoutState.allCases where state != .allocated {
            XCTAssertFalse(state.permitsPositiveTreatment, "\(state) must not permit positive treatment")
        }
        XCTAssertTrue(PayoutState.allocated.permitsPositiveTreatment)
    }

    // MARK: Canonical state flow

    func testCanonicalFlowStatesExist() {
        // DETECTED → PROCESSING → ALLOCATED plus failure branches.
        let raw = PayoutState.allCases.map(\.rawValue)
        for required in ["detected", "processing", "allocated", "failed", "returned", "reversed", "actionRequired", "unavailable"] {
            XCTAssertTrue(raw.contains(required), "missing canonical state \(required)")
        }
    }

    func testFailureBranchClassification() {
        XCTAssertTrue(PayoutState.failed.isFailureBranch)
        XCTAssertTrue(PayoutState.returned.isFailureBranch)
        XCTAssertTrue(PayoutState.reversed.isFailureBranch)
        XCTAssertTrue(PayoutState.actionRequired.isFailureBranch)
        XCTAssertTrue(PayoutState.unavailable.isFailureBranch)
        XCTAssertFalse(PayoutState.detected.isFailureBranch)
        XCTAssertFalse(PayoutState.processing.isFailureBranch)
        XCTAssertFalse(PayoutState.allocated.isFailureBranch)
    }

    // MARK: Receipt states match actual authority

    func testReceiptHeadlinesMatchAuthority() {
        XCTAssertEqual(PayoutState.detected.receiptHeadline, "Payout detected")
        XCTAssertEqual(PayoutState.processing.receiptHeadline, "Tax allocation processing")
        XCTAssertEqual(PayoutState.allocated.receiptHeadline, "Tax allocation confirmed")
        XCTAssertEqual(PayoutState.failed.receiptHeadline, "Allocation failed")
        XCTAssertEqual(PayoutState.reversed.receiptHeadline, "Reversed")
    }

    // MARK: Provenance labels are the closed set

    func testProvenanceLabelClosedSet() {
        let labels = Set(ProvenanceLabel.allCases.map(\.rawValue))
        XCTAssertEqual(labels, ["LIVE", "CACHED LIVE", "ESTIMATED", "USER ENTERED", "DEMO", "PREVIEW", "UNAVAILABLE"])
    }

    // MARK: Store honesty — no fabricated data in production path

    @MainActor
    func testStoreStartsEmptyAndUnavailable() {
        let store = TreasuryAutopilotStore()
        XCTAssertTrue(store.payouts.isEmpty, "production store must not seed payouts")
        XCTAssertEqual(store.accountStatus, .notOpened)
        XCTAssertEqual(store.provenance, .unavailable)
        XCTAssertNil(store.lastSyncedAt)
    }

    @MainActor
    func testDemoDataIsExplicitlyLabeled() {
        let store = TreasuryAutopilotStore()
        store.loadDemoData()
        XCTAssertEqual(store.provenance, .demo)
        XCTAssertTrue(store.payouts.allSatisfy { $0.provenance == .demo }, "every demo payout must carry the DEMO provenance label")
    }

    @MainActor
    func testIngestMarksLive() {
        let store = TreasuryAutopilotStore()
        store.ingest(
            payouts: [AutopilotPayout(id: "p1", platform: "DoorDash", grossAmountCents: 10000, state: .allocated)],
            accountStatus: .active,
            autopilot: AutopilotConfiguration(isEnabled: true, estimatedTaxRateBps: 3000)
        )
        XCTAssertEqual(store.provenance, .live)
        XCTAssertEqual(store.payouts.first?.state, .allocated)
        XCTAssertNotNil(store.lastSyncedAt)
    }

    // MARK: Amounts are Int64 cents

    func testAmountsAreCents() {
        let payout = AutopilotPayout(id: "p1", platform: "Uber", grossAmountCents: 21264, state: .detected)
        XCTAssertEqual(payout.grossAmountCents, 21264)
    }
}
