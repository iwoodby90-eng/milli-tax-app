import Foundation

// MARK: - MilliLedgerEngine
// Local financial ledger + reconciliation domain layer (closeout item 4).
//
// MilliLedger.swift (SwiftUI) remains a presentation component. This engine is
// the authoritative local ledger per money-movement state contract v2.1:
//   - append-only journal of money movements (no in-place mutation of history)
//   - balances derived by folding the journal, never stored and drifted
//   - reconciliation compares local journal state against provider-side state
//     and reports discrepancies; it NEVER fabricates provider state
//   - replay protection: a movement ID can be ingested only once

public struct MilliLedgerEntry: Equatable, Identifiable, Sendable {
    public enum Kind: Equatable, Sendable {
        case payout
        case taxReserveAllocation
        case taxPayment
        case transferIn
        case transferOut
        case reversal(of: String)
        case adjustment
    }

    public let id: String
    public let kind: Kind
    public let amountCents: Int64
    public let bucket: Bucket
    public let occurredAt: Date
    public let providerReference: String?
    public let memo: String?

    public enum Bucket: String, Equatable, Sendable {
        case operatingAccount
        case taxVault
    }
}

public struct MilliLedgerBalance: Equatable, Sendable {
    public var operatingAccountCents: Int64 = 0
    public var taxVaultCents: Int64 = 0
}

public enum MilliLedgerError: Error, Equatable {
    case duplicateEntry(String)
    case unknownReversalTarget(String)
    case reversalTargetAlreadyReversed(String)
    case reversalAmountMismatch(original: Int64, attempted: Int64)
    case reversalBucketMismatch(original: MilliLedgerEntry.Bucket, attempted: MilliLedgerEntry.Bucket)
    case invalidEntry(String)
}

public struct MilliReconciliationFinding: Equatable, Sendable {
    public enum Severity: Equatable, Hashable, Sendable {
        case missingLocally
        case missingAtProvider
        case amountMismatch(local: Int64, provider: Int64)
        case duplicateAtProvider(String)
    }
    public let providerReference: String
    public let severity: Severity
}

public struct MilliReconciliationReport: Equatable, Sendable {
    public let findings: [MilliReconciliationFinding]
    public let localBalance: MilliLedgerBalance
    public let providerBalanceCents: Int64?

    public var isClean: Bool { findings.isEmpty }
}

// MARK: - Engine

public final class MilliLedgerEngine: @unchecked Sendable {

    private(set) var entries: [MilliLedgerEntry] = []
    private var ingestedIDs: Set<String> = []
    private var reversedIDs: Set<String> = []
    private let lock = NSLock()

    public init() {}

    // MARK: Ingestion

    public func ingest(_ entry: MilliLedgerEntry) throws {
        lock.lock(); defer { lock.unlock() }
        try validate(entry)
        entries.append(entry)
        ingestedIDs.insert(entry.id)
        if case .reversal(let target) = entry.kind {
            reversedIDs.insert(target)
        }
    }

    private func validate(_ entry: MilliLedgerEntry) throws {
        if ingestedIDs.contains(entry.id) {
            throw MilliLedgerError.duplicateEntry(entry.id)
        }

        if case .reversal(let target) = entry.kind {
            guard let original = entries.first(where: { $0.id == target }) else {
                throw MilliLedgerError.unknownReversalTarget(target)
            }
            if reversedIDs.contains(target) {
                throw MilliLedgerError.reversalTargetAlreadyReversed(target)
            }
            if entry.amountCents != -original.amountCents {
                throw MilliLedgerError.reversalAmountMismatch(
                    original: original.amountCents,
                    attempted: entry.amountCents
                )
            }
            guard entry.bucket == original.bucket else {
                throw MilliLedgerError.reversalBucketMismatch(
                    original: original.bucket,
                    attempted: entry.bucket
                )
            }
        }

        if entry.id.isEmpty {
            throw MilliLedgerError.invalidEntry("empty id")
        }
    }

    // MARK: Derived balances

    public func balance() -> MilliLedgerBalance {
        lock.lock(); defer { lock.unlock() }
        return balanceLocked()
    }

    /// Caller must already hold `lock`.
    private func balanceLocked() -> MilliLedgerBalance {
        var balance = MilliLedgerBalance()
        for entry in entries {
            switch entry.bucket {
            case .operatingAccount:
                balance.operatingAccountCents += entry.amountCents
            case .taxVault:
                balance.taxVaultCents += entry.amountCents
            }
        }
        return balance
    }

    // MARK: Reconciliation

    public func reconcile(providerMovements: [ProviderMovement]) -> MilliReconciliationReport {
        lock.lock(); defer { lock.unlock() }

        var findings: [MilliReconciliationFinding] = []
        let localByRef = Dictionary(
            entries.filter { $0.providerReference != nil }.map { ($0.providerReference!, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var providerRefs: [String: Int] = [:]
        for provider in providerMovements {
            providerRefs[provider.reference, default: 0] += 1
            if providerRefs[provider.reference]! > 1 {
                findings.append(.init(
                    providerReference: provider.reference,
                    severity: .duplicateAtProvider(provider.reference)
                ))
                continue
            }

            if let local = localByRef[provider.reference] {
                if local.amountCents != provider.amountCents {
                    findings.append(.init(
                        providerReference: provider.reference,
                        severity: .amountMismatch(local: local.amountCents, provider: provider.amountCents)
                    ))
                }
            } else {
                findings.append(.init(
                    providerReference: provider.reference,
                    severity: .missingLocally
                ))
            }
        }

        for (reference, _) in localByRef where providerRefs[reference] == nil {
            findings.append(.init(
                providerReference: reference,
                severity: .missingAtProvider
            ))
        }

        let providerBalance = providerMovements.isEmpty && entries.contains(where: { $0.providerReference != nil })
            ? nil
            : providerMovements.reduce(0) { $0 + $1.amountCents }

        return MilliReconciliationReport(
            findings: findings,
            localBalance: balanceLocked(),
            providerBalanceCents: providerBalance
        )
    }

    public struct ProviderMovement: Equatable, Sendable {
        public let reference: String
        public let amountCents: Int64

        public init(reference: String, amountCents: Int64) {
            self.reference = reference
            self.amountCents = amountCents
        }
    }
}
