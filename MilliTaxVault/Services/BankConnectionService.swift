import SwiftUI
import Combine

// MARK: - BankConnectionService
// Banking integration service supporting both Stripe Financial Connections and Plaid Link.
// Manages real-time bank aggregation, verified direct deposits, and gig platform payout synchronization.

public enum BankConnectionProvider: String, CaseIterable, Codable, Identifiable {
    case stripeFinancialConnections = "Stripe Financial Connections"
    case plaid = "Plaid Link"

    public var id: String { rawValue }

    public var badgeTitle: String {
        switch self {
        case .stripeFinancialConnections: return "STRIPE SECURED"
        case .plaid: return "PLAID VERIFIED"
        }
    }

    public var iconName: String {
        switch self {
        case .stripeFinancialConnections: return "lock.shield.fill"
        case .plaid: return "building.columns.fill"
        }
    }
}

public struct BankInstitution: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let routingPrefix: String
    public let logoIcon: String
    public let isPopular: Bool

    public static let standardInstitutions: [BankInstitution] = [
        .init(id: "chase", name: "Chase Bank", routingPrefix: "021000021", logoIcon: "building.columns.fill", isPopular: true),
        .init(id: "bofa", name: "Bank of America", routingPrefix: "026009593", logoIcon: "building.columns.fill", isPopular: true),
        .init(id: "wells", name: "Wells Fargo", routingPrefix: "121000247", logoIcon: "building.columns.fill", isPopular: true),
        .init(id: "citi", name: "Citibank", routingPrefix: "021000089", logoIcon: "building.columns.fill", isPopular: true),
        .init(id: "capone", name: "Capital One", routingPrefix: "051405515", logoIcon: "building.columns.fill", isPopular: true),
        .init(id: "usbank", name: "U.S. Bank", routingPrefix: "091000022", logoIcon: "building.columns.fill", isPopular: false),
        .init(id: "dasher", name: "DasherDirect Business Prepaid", routingPrefix: "071123456", logoIcon: "bag.fill", isPopular: true),
        .init(id: "uberpro", name: "Uber Pro Card (Branch)", routingPrefix: "084312345", logoIcon: "car.fill", isPopular: true),
        .init(id: "chime", name: "Chime (The Bancorp Bank)", routingPrefix: "031101279", logoIcon: "creditcard.fill", isPopular: true),
        .init(id: "navyfed", name: "Navy Federal Credit Union", routingPrefix: "256074974", logoIcon: "shield.fill", isPopular: false)
    ]
}

public struct ConnectedBankAccount: Identifiable, Codable, Equatable {
    public let id: String
    public let institutionName: String
    public let accountName: String
    public let accountMask: String
    public let accountType: String
    public var balance: Double
    public let provider: BankConnectionProvider
    public var lastSyncedAt: Date
    public var isLive: Bool

    public var displayTitle: String {
        "\(institutionName) \(accountName) ····\(accountMask)"
    }
}

public struct GigPlatformLink: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let assetName: String?
    public let primaryColorHex: String
    public var isConnected: Bool
    public var autoSyncPayouts: Bool

    public static let standardPlatforms: [GigPlatformLink] = [
        .init(id: "doordash", name: "DoorDash", assetName: "doordash-icon", primaryColorHex: "FF3008", isConnected: true, autoSyncPayouts: true),
        .init(id: "uber", name: "Uber / Uber Eats", assetName: "uber-icon", primaryColorHex: "000000", isConnected: true, autoSyncPayouts: true),
        .init(id: "spark", name: "Spark Driver", assetName: "spark-driver-icon", primaryColorHex: "0071DC", isConnected: true, autoSyncPayouts: true),
        .init(id: "amazonflex", name: "Amazon Flex", assetName: "amazon-flex-icon", primaryColorHex: "FF9900", isConnected: true, autoSyncPayouts: true),
        .init(id: "instacart", name: "Instacart", assetName: "instacart-icon", primaryColorHex: "16844A", isConnected: true, autoSyncPayouts: true),
        .init(id: "grubhub", name: "Grubhub", assetName: nil, primaryColorHex: "C44724", isConnected: true, autoSyncPayouts: true),
        .init(id: "lyft", name: "Lyft Driver", assetName: nil, primaryColorHex: "FF00BF", isConnected: false, autoSyncPayouts: false)
    ]
}

public struct VerifiedPayout: Identifiable, Codable, Equatable {
    public let id: String
    public let receiptCode: String
    public let platform: String
    public let platformInitial: String
    public let assetName: String?
    public let platformColorHex: String
    public let dateLabel: String
    public let grossAmount: Double
    public let isPending: Bool
    public let isThisWeek: Bool
    public let bankMask: String
    public let achTraceId: String

    public var taxProtected: Double { (grossAmount * 0.30).rounded(to: 2) }
    public var retirementAllocation: Double { (grossAmount * 0.10).rounded(to: 2) }
    public var investingAllocation: Double { (grossAmount * 0.10).rounded(to: 2) }
    public var emergencySavings: Double { (grossAmount * 0.05).rounded(to: 2) }
    public var availableToSpend: Double {
        (grossAmount - taxProtected - retirementAllocation - investingAllocation - emergencySavings).rounded(to: 2)
    }

    public var platformColor: Color {
        Color(hex: platformColorHex)
    }

    public var stateContractProjection: AutopilotPayout {
        AutopilotPayout(
            id: id,
            platform: platform,
            grossAmountCents: Int64((grossAmount * 100).rounded()),
            state: .detected,
            provenance: .cachedLive
        )
    }
}

private extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - BankConnectionService Manager

@MainActor
public final class BankConnectionService: ObservableObject {
    public static let shared = BankConnectionService()

    @Published public var connectedBank: ConnectedBankAccount? {
        didSet { persist() }
    }
    @Published public var linkedPlatforms: [GigPlatformLink] = GigPlatformLink.standardPlatforms {
        didSet { persist() }
    }
    @Published public var payouts: [VerifiedPayout] = [] {
        didSet { persist() }
    }
    @Published public var isConnecting: Bool = false
    @Published public var isSyncing: Bool = false
    @Published public var syncMessage: String?
    @Published public private(set) var taxVaultReserveBalance: Double = 0
    @Published public private(set) var lastPayoutSyncAt: Date?

    private let storageKeyBank = "milli_connected_bank_v2"
    private let storageKeyPlatforms = "milli_linked_platforms_v2"
    private let storageKeyPayouts = "milli_verified_payouts_v2"

    private init() {
        loadPersistedData()
    }

    public var totalPayoutsAmount: Double {
        payouts.reduce(0) { $0 + $1.grossAmount }
    }

    public func connectBankViaHostedFlow() async {
        guard !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }

        let accounts: ConnectedAccountsResponse? = await withCheckedContinuation { continuation in
            BankLinkCoordinator.shared.startLink(presentationContext: ASPresentationAnchor()) { result in
                continuation.resume(returning: result)
            }
        }

        guard let accounts, let primary = accounts.accounts.first else {
            return
        }

        connectedBank = ConnectedBankAccount(
            id: primary.id,
            institutionName: primary.institutionName,
            accountName: primary.accountName,
            accountMask: primary.accountMask,
            accountType: primary.accountType,
            balance: primary.balance,
            provider: .stripeFinancialConnections,
            lastSyncedAt: primary.lastSyncedAt,
            isLive: true
        )

        await syncTransactions()
    }

    public func connectBank(institution: BankInstitution, provider: BankConnectionProvider, accountMask: String = "4821") {
        isConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self else { return }
            self.connectedBank = ConnectedBankAccount(
                id: "\(provider == .stripeFinancialConnections ? "stripe" : "plaid")_\(institution.id)_\(accountMask)",
                institutionName: institution.name,
                accountName: "Primary Checking",
                accountMask: accountMask,
                accountType: "Checking",
                balance: 0,
                provider: provider,
                lastSyncedAt: Date(),
                isLive: false
            )
            self.isConnecting = false
        }
    }

    public func disconnectBank() {
        connectedBank = nil
        payouts.removeAll()
    }

    public func syncTransactions() async {
        guard let bank = connectedBank else { return }
        guard MilliBackendClient.shared.isConfigured else {
            syncMessage = "Milli backend not configured."
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let sync = try await MilliBackendClient.shared.syncPayouts(accountId: bank.id)
            payouts = sync.payouts.map { payload in
                let platformMatch = GigPlatformLink.standardPlatforms.first {
                    $0.name.lowercased().contains(payload.platform.lowercased())
                }
                return VerifiedPayout(
                    id: payload.id,
                    receiptCode: "FC-\(payload.id.suffix(6))",
                    platform: payload.platform,
                    platformInitial: String(payload.platform.prefix(1)),
                    assetName: platformMatch?.assetName,
                    platformColorHex: platformMatch?.primaryColorHex ?? "00E5FF",
                    dateLabel: payload.detectedAt.formatted(date: .abbreviated, time: .omitted),
                    grossAmount: payload.grossAmount,
                    isPending: payload.taxHoldState != "confirmed",
                    isThisWeek: Calendar.current.isDateInWeek(payload.detectedAt),
                    bankMask: bank.accountMask,
                    achTraceId: payload.id
                )
            }
            taxVaultReserveBalance = sync.taxVaultReserveBalance
            lastPayoutSyncAt = sync.syncedAt
            connectedBank?.lastSyncedAt = sync.syncedAt
            syncMessage = nil
        } catch {
            syncMessage = error.localizedDescription
        }
    }

    public func togglePlatform(id: String) {
        if let idx = linkedPlatforms.firstIndex(where: { $0.id == id }) {
            linkedPlatforms[idx].isConnected.toggle()
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let bankData = try? encoder.encode(connectedBank) {
            UserDefaults.standard.set(bankData, forKey: storageKeyBank)
        }
        if let platformData = try? encoder.encode(linkedPlatforms) {
            UserDefaults.standard.set(platformData, forKey: storageKeyPlatforms)
        }
        if let payoutData = try? encoder.encode(payouts) {
            UserDefaults.standard.set(payoutData, forKey: storageKeyPayouts)
        }
    }

    private func loadPersistedData() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: storageKeyBank),
           let bank = try? decoder.decode(ConnectedBankAccount?.self, from: data) {
            connectedBank = bank
        }
        if let data = UserDefaults.standard.data(forKey: storageKeyPlatforms),
           let platforms = try? decoder.decode([GigPlatformLink].self, from: data) {
            linkedPlatforms = platforms
        }
        if let data = UserDefaults.standard.data(forKey: storageKeyPayouts),
           let savedPayouts = try? decoder.decode([VerifiedPayout].self, from: data) {
            payouts = savedPayouts
        }
    }
}
