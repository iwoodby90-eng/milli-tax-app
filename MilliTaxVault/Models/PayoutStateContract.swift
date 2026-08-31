import Foundation

// MARK: - PayoutStateContract
// Canonical money-movement state contract for the Stripe Treasury Autopilot UI.
// Mirrors the Canonical Money-Movement State Contract v2.1 (backend authority).
// HARD RULE: the UI renders backend/provider states only. SwiftUI never
// determines financial truth. No view may display LIVE / POSTED / PROTECTED /
// SETTLED / ALLOCATED unless the authoritative backend state confirms it.

/// Canonical payout state flow: DETECTED → PROCESSING → ALLOCATED,
/// plus failure branches FAILED / RETURNED / REVERSED / ACTION_REQUIRED / UNAVAILABLE.
public enum PayoutState: String, Codable, CaseIterable, Sendable {
    case detected
    case processing
    case allocated
    case failed
    case returned
    case reversed
    case actionRequired
    case unavailable

    /// True only when the authoritative backend has confirmed Tax Vault
    /// allocation. Until then funds are part of the operating balance and
    /// must NOT visually appear protected.
    public var isTaxProtected: Bool { self == .allocated }

    /// Receipt states must match actual authority:
    /// payout detected / tax allocation processing / tax allocation confirmed /
    /// failed / reversed.
    public var receiptHeadline: String {
        switch self {
        case .detected: return "Payout detected"
        case .processing: return "Tax allocation processing"
        case .allocated: return "Tax allocation confirmed"
        case .failed: return "Allocation failed"
        case .returned: return "Payout returned"
        case .reversed: return "Reversed"
        case .actionRequired: return "Action required"
        case .unavailable: return "Unavailable"
        }
    }

    /// States that represent a terminal failure branch.
    public var isFailureBranch: Bool {
        switch self {
        case .failed, .returned, .reversed, .actionRequired, .unavailable: return true
        default: return false
        }
    }

    /// Celebration is only permitted for confirmed, completed outcomes.
    /// Never celebrate a requested or processing transaction.
    public var permitsPositiveTreatment: Bool { self == .allocated }
}

/// Provenance labels — the ONLY labels the UI may display for data origin.
public enum ProvenanceLabel: String, CaseIterable, Sendable {
    case live = "LIVE"
    case cached = "CACHED"
    case userEntered = "USER ENTERED"
    case demo = "DEMO"
    case preview = "PREVIEW"
    case unavailable = "UNAVAILABLE"
}

/// Authoritative payout record as delivered by the backend. The client
/// renders this; it never synthesizes it.
public struct AutopilotPayout: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let platform: String
    public let grossAmountCents: Int64
    public let state: PayoutState
    public let detectedAt: Date?
    public let allocatedAt: Date?
    public let provenance: ProvenanceLabel

    public init(
        id: String,
        platform: String,
        grossAmountCents: Int64,
        state: PayoutState,
        detectedAt: Date? = nil,
        allocatedAt: Date? = nil,
        provenance: ProvenanceLabel = .live
    ) {
        self.id = id
        self.platform = platform
        self.grossAmountCents = grossAmountCents
        self.state = state
        self.detectedAt = detectedAt
        self.allocatedAt = allocatedAt
        self.provenance = provenance
    }

    /// Tax Vault allocation amount, in cents, as reported by the backend.
    /// The client does not compute financial truth; this is a display
    /// decomposition only when the backend supplies the rate.
    public var taxAllocatedCents: Int64? { nil }
}

/// MILLI Financial Account (Stripe Financial Account / Treasury) status
/// as reported by the backend.
public enum FinancialAccountStatus: String, Codable, Sendable {
    case notOpened
    case pendingActivation
    case active
    case restricted
    case closed
    case unavailable
}

/// Autopilot configuration as stored server-side; the UI reflects it.
public struct AutopilotConfiguration: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var estimatedTaxRateBps: Int?
    public init(isEnabled: Bool = false, estimatedTaxRateBps: Int? = nil) {
        self.isEnabled = isEnabled
        self.estimatedTaxRateBps = estimatedTaxRateBps
    }
}
