import Foundation

// MARK: - Bank-linked Autopilot profile
// This model describes the consent and routing state required for Milli to detect
// gig payouts, calculate a tax reserve, and initiate a transfer into Milli Tax Vault™.
// Provider credentials and money movement remain server-side responsibilities.

struct BankAutopilotProfile: Codable, Equatable {
    var connectionStatus: BankConnectionStatus = .notConnected
    var institutionName: String = ""
    var accountName: String = ""
    var accountLastFour: String = ""
    var selectedPlatforms: Set<GigPlatform> = []
    var autoDetectPlatforms: Bool = true
    var transactionMonitoringConsent: Bool = false
    var taxVaultTransferConsent: Bool = false

    var isReadyForAutopilot: Bool {
        connectionStatus == .connected
            && transactionMonitoringConsent
            && taxVaultTransferConsent
    }
}

enum BankConnectionStatus: String, Codable, CaseIterable {
    case notConnected
    case connecting
    case connected
    case needsAttention
}

enum GigPlatform: String, Codable, CaseIterable, Hashable, Identifiable {
    case amazonFlex = "Amazon Flex"
    case sparkDriver = "Spark Driver"
    case uber = "Uber"
    case lyft = "Lyft"
    case doorDash = "DoorDash"
    case grubhub = "Grubhub"
    case instacart = "Instacart"
    case roadie = "Roadie"
    case shipt = "Shipt"
    case other = "Other"

    var id: String { rawValue }

    /// Merchant/transaction descriptors seen in bank transaction feeds can vary
    /// by institution. These are normalization hints only; production matching
    /// should also use provider merchant metadata and server-side model updates.
    var descriptorHints: [String] {
        switch self {
        case .amazonFlex:
            return ["AMAZON FLEX", "AMZN FLEX", "AMAZON.COM SERVICES"]
        case .sparkDriver:
            return ["SPARK DRIVER", "WALMART SPARK", "DDI SPARK"]
        case .uber:
            return ["UBER", "UBER TECHNOLOGIES", "UBER PAY"]
        case .lyft:
            return ["LYFT", "LYFT DRIVER"]
        case .doorDash:
            return ["DOORDASH", "DASHER", "DOORDASH PAY"]
        case .grubhub:
            return ["GRUBHUB", "GRUBHUB DRIVER"]
        case .instacart:
            return ["INSTACART", "MAPLEBEAR", "INSTACART SHOPPER"]
        case .roadie:
            return ["ROADIE", "ROADIE DRIVER"]
        case .shipt:
            return ["SHIPT", "SHIPT SHOPPER"]
        case .other:
            return []
        }
    }
}

// MARK: - Payout detection

struct BankTransactionObservation: Equatable {
    let id: String
    let postedAt: Date
    let amount: Decimal
    let description: String
    let merchantName: String?
    let isPending: Bool
}

struct DetectedGigPayout: Equatable {
    let transactionID: String
    let platform: GigPlatform
    let grossAmount: Decimal
    let postedAt: Date
    let confidence: Double
}

enum GigPayoutDetectionEngine {
    /// Detects likely gig-platform credits from normalized bank transaction data.
    /// This is deterministic and intentionally conservative. A server-side
    /// production implementation should combine provider merchant metadata,
    /// user-confirmed platforms, historical patterns, and duplicate protection.
    static func detect(
        transaction: BankTransactionObservation,
        allowedPlatforms: Set<GigPlatform> = Set(GigPlatform.allCases)
    ) -> DetectedGigPayout? {
        guard !transaction.isPending, transaction.amount > 0 else { return nil }

        let searchable = [transaction.description, transaction.merchantName ?? ""]
            .joined(separator: " ")
            .uppercased()

        let candidates = allowedPlatforms.filter { $0 != .other }

        for platform in candidates {
            if platform.descriptorHints.contains(where: { searchable.contains($0) }) {
                return DetectedGigPayout(
                    transactionID: transaction.id,
                    platform: platform,
                    grossAmount: transaction.amount,
                    postedAt: transaction.postedAt,
                    confidence: 0.92
                )
            }
        }

        return nil
    }
}

// MARK: - Tax Vault transfer instruction

struct TaxVaultTransferInstruction: Equatable {
    let payout: DetectedGigPayout
    let taxReserveAmount: Decimal
    let sourceAccountLastFour: String
    let idempotencyKey: String
}

enum TaxVaultTransferPlanner {
    static func instruction(
        for payout: DetectedGigPayout,
        taxRate: Decimal,
        sourceAccountLastFour: String
    ) -> TaxVaultTransferInstruction {
        let clampedRate = min(max(taxRate, 0), 1)
        let reserve = (payout.grossAmount * clampedRate).roundedToCents()

        return TaxVaultTransferInstruction(
            payout: payout,
            taxReserveAmount: reserve,
            sourceAccountLastFour: sourceAccountLastFour,
            idempotencyKey: "tax-vault-\(payout.transactionID)"
        )
    }
}

private extension Decimal {
    func roundedToCents() -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, 2, .bankers)
        return result
    }
}
