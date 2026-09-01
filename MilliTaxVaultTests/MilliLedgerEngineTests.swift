import XCTest
@testable import MilliTaxVault

final class MilliLedgerEngineTests: XCTestCase {

    private func payout(_ id: String, _ cents: Int64, ref: String? = nil,
                        bucket: MilliLedgerEntry.Bucket = .operatingAccount) -> MilliLedgerEntry {
        MilliLedgerEntry(id: id, kind: .payout, amountCents: cents, bucket: bucket,
                         occurredAt: Date(), providerReference: ref, memo: nil)
    }

    // MARK: Append-only + derived balances

    func testBalanceFoldsJournal() throws {
        let engine = MilliLedgerEngine()
        try engine.ingest(payout("a", 4_311, ref: "pmt_a"))
        try engine.ingest(MilliLedgerEntry(id: "b", kind: .taxReserveAllocation,
                                           amountCents: -992, bucket: .operatingAccount,
                                           occurredAt: Date(), providerReference: "alloc_b", memo: nil))
        try engine.ingest(MilliLedgerEntry(id: "c", kind: .taxReserveAllocation,
                                           amountCents: 992, bucket: .taxVault,
                                           occurredAt: Date(), providerReference: "alloc_b_vault", memo: nil))
        let bal = engine.balance()
        XCTAssertEqual(bal.operatingAccountCents, 4_311 - 992)
        XCTAssertEqual(bal.taxVaultCents, 992)
    }

    // MARK: Replay protection

    func testDuplicateIngestRejectedLedgerUntouched() throws {
        let engine = MilliLedgerEngine()
        try engine.ingest(payout("a", 100, ref: "pmt_a"))
        XCTAssertThrowsError(try engine.ingest(payout("a", 100, ref: "pmt_a"))) { error in
            guard case MilliLedgerError.duplicateEntry("a") = error else {
                return XCTFail("wrong error: \(error)")
            }
        }
        XCTAssertEqual(engine.entries.count, 1)
        XCTAssertEqual(engine.balance().operatingAccountCents, 100)
    }

    // MARK: Reversal rules (validate before mutate)

    func testReversalMustReferenceExistingMovement() {
        let engine = MilliLedgerEngine()
        let reversal = MilliLedgerEntry(id: "r", kind: .reversal(of: "ghost"),
                                        amountCents: -100, bucket: .operatingAccount,
                                        occurredAt: Date(), providerReference: nil, memo: nil)
        XCTAssertThrowsError(try engine.ingest(reversal)) { error in
            XCTAssertEqual(error as? MilliLedgerError, .unknownReversalTarget("ghost"))
        }
        XCTAssertTrue(engine.entries.isEmpty)
    }

    func testReversalMustMirrorAmountAndCannotDoubleReverse() throws {
        let engine = MilliLedgerEngine()
        try engine.ingest(payout("a", 500, ref: "pmt_a"))
        let bad = MilliLedgerEntry(id: "r1", kind: .reversal(of: "a"),
                                   amountCents: -400, bucket: .operatingAccount,
                                   occurredAt: Date(), providerReference: nil, memo: nil)
        XCTAssertThrowsError(try engine.ingest(bad)) { error in
            XCTAssertEqual(error as? MilliLedgerError,
                            .reversalAmountMismatch(original: 500, attempted: -400))
        }
        let good = MilliLedgerEntry(id: "r2", kind: .reversal(of: "a"),
                                    amountCents: -500, bucket: .operatingAccount,
                                    occurredAt: Date(), providerReference: nil, memo: nil)
        try engine.ingest(good)
        XCTAssertEqual(engine.balance().operatingAccountCents, 0)
        let doubleReverse = MilliLedgerEntry(id: "r3", kind: .reversal(of: "a"),
                                             amountCents: -500, bucket: .operatingAccount,
                                             occurredAt: Date(), providerReference: nil, memo: nil)
        XCTAssertThrowsError(try engine.ingest(doubleReverse)) { error in
            XCTAssertEqual(error as? MilliLedgerError, .reversalTargetAlreadyReversed("a"))
        }
    }

    // MARK: Reconciliation

    func testCleanReconciliation() throws {
        let engine = MilliLedgerEngine()
        try engine.ingest(payout("a", 100, ref: "pmt_a"))
        let report = engine.reconcile(providerMovements: [
            .init(reference: "pmt_a", amountCents: 100),
        ])
        XCTAssertTrue(report.isClean)
        XCTAssertEqual(report.providerBalanceCents, 100)
    }

    func testDiscrepanciesDetected() throws {
        let engine = MilliLedgerEngine()
        try engine.ingest(payout("a", 100, ref: "pmt_a"))
        try engine.ingest(payout("b", 200, ref: "pmt_b"))
        let report = engine.reconcile(providerMovements: [
            .init(reference: "pmt_a", amountCents: 150),          // amount mismatch
            .init(reference: "pmt_c", amountCents: 300),          // missing locally
        ])
        XCTAssertEqual(report.findings.count, 3) // + pmt_b missing at provider
        let severities = Set(report.findings.map { $0.severity })
        XCTAssertTrue(severities.contains(.amountMismatch(local: 100, provider: 150)))
        XCTAssertTrue(severities.contains { if case .missingLocally = $0 { return true }; return false })
        XCTAssertTrue(severities.contains { if case .missingAtProvider = $0 { return true }; return false })
    }

    func testProviderSilenceDoesNotClaimZeroBalance() throws {
        let engine = MilliLedgerEngine()
        try engine.ingest(payout("a", 100, ref: "pmt_a"))
        let report = engine.reconcile(providerMovements: [])
        XCTAssertNil(report.providerBalanceCents, "must not fabricate a zero provider balance")
        XCTAssertEqual(report.findings.count, 1)
    }
}
