import Foundation

// MARK: - TreasuryExecutionService
// Server-side execution path for the Stripe Treasury money-movement rail
// (closeout item 2). The client-side state contract (PayoutStateContract /
// TreasuryAutopilotStore) is landed; this service is the authoritative
// backend driver. No SwiftUI simulation may substitute for provider state —
// this file contains no UI and never invents provider outcomes.

/// The authoritative money-movement states, backend-assigned only.
/// Mirrors money-movement state contract v2.1.
public enum TreasuryMovementState: String, Equatable, Sendable, CaseIterable {
    case detected        = "DETECTED"
    case processing      = "PROCESSING"
    case allocated      = "ALLOCATED"
    case failed         = "FAILED"
    case returned       = "RETURNED"
    case reversed       = "REVERSED"
    case actionRequired = "ACTION_REQUIRED"
    case unavailable    = "UNAVAILABLE"
}

/// Provider-agnostic port the backend implements against Stripe Treasury
/// (FinancialAccount, OutboundPayment/OutboundTransfer, InboundPayment).
/// The domain layer depends only on this protocol — never on Stripe types —
/// so tests run against a deterministic fake and production swaps the adapter.
public protocol TreasuryProviderPort: Sendable {
    /// Initiate the allocation movement at the provider. Returns the provider
    /// reference, or throws on transport/auth failure (which maps to UNAVAILABLE,
    /// never to FAILED — the movement never started).
    func initiateAllocation(reference: String, amountCents: Int64) async throws -> String
    /// Fetch the authoritative provider-side state for a reference.
    func fetchState(reference: String) async throws -> TreasuryMovementState
}

public struct TreasuryMovementRecord: Equatable, Sendable {
    public let reference: String
    public let amountCents: Int64
    public let state: TreasuryMovementState
    public let updatedAt: Date
}

public enum TreasuryExecutionError: Error, Equatable {
    case invalidTransition(from: TreasuryMovementState, to: TreasuryMovementState)
    case providerUnavailable(String)
    case unknownMovement(String)
}

// MARK: - Legal state machine (v2.1)

public enum TreasuryStateMachine {

    /// Backend-authoritative transitions. Client code may read but never widen this.
    public static func canTransition(_ from: TreasuryMovementState, to: TreasuryMovementState) -> Bool {
        switch (from, to) {
        // Happy path
        case (.detected, .processing), (.processing, .allocated): return true
        // Failure paths
        case (.detected, .failed), (.processing, .failed): return true
        case (.processing, .returned), (.allocated, .returned): return true
        case (.allocated, .reversed): return true
        // Operator intervention
        case (.actionRequired, .processing), (.actionRequired, .failed): return true
        case (.detected, .actionRequired), (.processing, .actionRequired),
             (.failed, .actionRequired), (.returned, .actionRequired): return true
        // Degraded mode
        case (_, .unavailable): return true
        case (.unavailable, .detected), (.unavailable, .processing): return true
        default: return false
        }
    }
}

// MARK: - Service

/// Server-side orchestrator: drives movements through the provider port and
/// records authoritative state. States are set ONLY from provider responses
/// (or transport failure → UNAVAILABLE). Nothing here is simulated.
public actor TreasuryExecutionService {

    private var records: [String: TreasuryMovementRecord] = [:]
    private let provider: TreasuryProviderPort

    public init(provider: TreasuryProviderPort) {
        self.provider = provider
    }

    /// A payout was detected (e.g. by webhook ingest). Creates the movement in
    /// DETECTED. Idempotent on reference.
    public func recordDetection(reference: String, amountCents: Int64) -> TreasuryMovementRecord {
        if let existing = records[reference] { return existing }
        let record = TreasuryMovementRecord(reference: reference, amountCents: amountCents,
                                            state: .detected, updatedAt: Date())
        records[reference] = record
        return record
    }

    /// Execute the allocation for a DETECTED movement. On transport failure the
    /// movement goes UNAVAILABLE (it never started — not FAILED). On success it
    /// moves PROCESSING and the provider reference is authoritative.
    public func executeAllocation(reference: String) async throws -> TreasuryMovementRecord {
        guard let record = records[reference] else {
            throw TreasuryExecutionError.unknownMovement(reference)
        }
        guard TreasuryStateMachine.canTransition(record.state, to: .processing) else {
            throw TreasuryExecutionError.invalidTransition(from: record.state, to: .processing)
        }
        do {
            _ = try await provider.initiateAllocation(reference: reference,
                                                      amountCents: record.amountCents)
            records[reference] = TreasuryMovementRecord(reference: reference,
                                                         amountCents: record.amountCents,
                                                         state: .processing,
                                                         updatedAt: Date())
            return records[reference]!
        } catch {
            records[reference] = TreasuryMovementRecord(reference: reference,
                                                         amountCents: record.amountCents,
                                                         state: .unavailable,
                                                         updatedAt: Date())
            throw TreasuryExecutionError.providerUnavailable(String(describing: error))
        }
    }

    /// Apply an authoritative provider state update (webhook / poll).
    /// Rejects illegal transitions instead of guessing.
    public func applyProviderState(reference: String, state: TreasuryMovementState) throws -> TreasuryMovementRecord {
        guard let record = records[reference] else {
            throw TreasuryExecutionError.unknownMovement(reference)
        }
        guard TreasuryStateMachine.canTransition(record.state, to: state) else {
            throw TreasuryExecutionError.invalidTransition(from: record.state, to: state)
        }
        records[reference] = TreasuryMovementRecord(reference: reference,
                                                     amountCents: record.amountCents,
                                                     state: state,
                                                     updatedAt: Date())
        return records[reference]!
    }

    public func currentState(reference: String) -> TreasuryMovementRecord? {
        records[reference]
    }
}
