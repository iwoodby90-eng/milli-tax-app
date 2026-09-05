import Foundation

// MARK: - TreasuryExecutionService
// Server-side execution path for the Stripe Treasury money-movement rail
// (closeout item 2). The client-side state contract (PayoutStateContract /
// TreasuryAutopilotStore) is landed; this service is the authoritative
// backend driver. No SwiftUI simulation may substitute for provider state —
// this file contains no UI and never invents provider outcomes.

public enum TreasuryMovementState: String, Equatable, Sendable, CaseIterable {
    case detected        = "DETECTED"
    case processing      = "PROCESSING"
    case allocated       = "ALLOCATED"
    case failed          = "FAILED"
    case returned        = "RETURNED"
    case reversed        = "REVERSED"
    case actionRequired  = "ACTION_REQUIRED"
    case unavailable     = "UNAVAILABLE"
}

public protocol TreasuryProviderPort: Sendable {
    func initiateAllocation(reference: String, amountCents: Int64) async throws -> String
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

    public static func canTransition(_ from: TreasuryMovementState, to: TreasuryMovementState) -> Bool {
        switch (from, to) {
        case (.detected, .processing), (.processing, .allocated): return true
        case (.detected, .failed), (.processing, .failed): return true
        case (.processing, .returned), (.allocated, .returned): return true
        case (.allocated, .reversed): return true
        case (.actionRequired, .processing), (.actionRequired, .failed): return true
        case (.detected, .actionRequired), (.processing, .actionRequired),
             (.failed, .actionRequired), (.returned, .actionRequired): return true
        case (_, .unavailable): return true
        case (.unavailable, .detected), (.unavailable, .processing): return true
        default: return false
        }
    }
}

// MARK: - Service

public actor TreasuryExecutionService {

    private var records: [String: TreasuryMovementRecord] = [:]
    private let provider: TreasuryProviderPort

    public init(provider: TreasuryProviderPort) {
        self.provider = provider
    }

    public func recordDetection(reference: String, amountCents: Int64) -> TreasuryMovementRecord {
        if let existing = records[reference] {
            return existing
        }

        let record = TreasuryMovementRecord(
            reference: reference,
            amountCents: amountCents,
            state: .detected,
            updatedAt: Date()
        )
        records[reference] = record
        return record
    }

    /// Starts an allocation exactly once per detected reference.
    ///
    /// The record is moved to PROCESSING before the provider await. Swift actors
    /// are reentrant across suspension points; publishing PROCESSING first means a
    /// concurrent webhook retry observes the in-flight state and returns it rather
    /// than initiating a second money movement.
    public func executeAllocation(reference: String) async throws -> TreasuryMovementRecord {
        guard let record = records[reference] else {
            throw TreasuryExecutionError.unknownMovement(reference)
        }

        if record.state == .processing {
            return record
        }

        guard TreasuryStateMachine.canTransition(record.state, to: .processing) else {
            throw TreasuryExecutionError.invalidTransition(from: record.state, to: .processing)
        }

        let processing = TreasuryMovementRecord(
            reference: reference,
            amountCents: record.amountCents,
            state: .processing,
            updatedAt: Date()
        )
        records[reference] = processing

        do {
            _ = try await provider.initiateAllocation(
                reference: reference,
                amountCents: record.amountCents
            )

            // A provider webhook may have advanced the state while the actor was
            // suspended. Never overwrite a newer authoritative state with PROCESSING.
            guard let latest = records[reference] else {
                throw TreasuryExecutionError.unknownMovement(reference)
            }
            return latest
        } catch {
            let unavailable = TreasuryMovementRecord(
                reference: reference,
                amountCents: record.amountCents,
                state: .unavailable,
                updatedAt: Date()
            )
            records[reference] = unavailable
            throw TreasuryExecutionError.providerUnavailable(String(describing: error))
        }
    }

    /// Applies an authoritative provider state update. Repeated delivery of the
    /// same state is an idempotent no-op, which is required for webhook retries
    /// and polling convergence.
    public func applyProviderState(reference: String, state: TreasuryMovementState) throws -> TreasuryMovementRecord {
        guard let record = records[reference] else {
            throw TreasuryExecutionError.unknownMovement(reference)
        }

        if record.state == state {
            return record
        }

        guard TreasuryStateMachine.canTransition(record.state, to: state) else {
            throw TreasuryExecutionError.invalidTransition(from: record.state, to: state)
        }

        let updated = TreasuryMovementRecord(
            reference: reference,
            amountCents: record.amountCents,
            state: state,
            updatedAt: Date()
        )
        records[reference] = updated
        return updated
    }

    public func currentState(reference: String) -> TreasuryMovementRecord? {
        records[reference]
    }
}
