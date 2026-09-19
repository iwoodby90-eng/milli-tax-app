import SwiftUI
import Combine

// MARK: - BankConnectionService
// Native projection of Milli's authenticated Plaid connection. Plaid is the
// only external account-connectivity provider. Column remains server-side and
// owns banking / ACH money movement.

public struct ConnectedBankAccount: Identifiable, Codable, Equatable {
    public let id: String
    public let institutionName: String
    public let accountName: String
    public let accountMask: String
    public let accountType: String
    public var balance: Double
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

    // Production defaults are intentionally neutral. The app never claims a
    // gig platform is connected until the user explicitly confirms it.
    public static let standardPlatforms: [GigPlatformLink] = [
        .init(id: "doordash", name: "DoorDash", assetName: "doordash-icon", primaryColorHex: "FF3008", isConnected: false, autoSyncPayouts: false),
        .init(id: "uber", name: "Uber / Uber Eats", assetName: "uber-icon", primaryColorHex: "000000", isConnected: false, autoSyncPayouts: false),
        .init(id: "spark", name: "Spark Driver", assetName: "spark-driver-icon", primaryColorHex: "0071DC", isConnected: false, autoSyncPayouts: false),
        .init(id: "amazonflex", name: "Amazon Flex", assetName: "amazon-flex-icon", primaryColorHex: "FF9900", isConnected: false, autoSyncPayouts: false),
        .init(id: "instacart", name: "Instacart", assetName: "instacart-icon", primaryColorHex: "16844A", isConnected: false, autoSyncPayouts: false),
        .init(id: "grubhub", name: "Grubhub", assetName: nil, primaryColorHex: "C44724", isConnected: false, autoSyncPayouts: false),
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

    public var platformColor: Color {
        Color(hex: platformColorHex)
    }

    /// A locally cached payout has no settlement authority. It can be shown only
    /// as a detected cached record until the backend confirms later states.
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
    @Published public var isSyncing: Bool = false
    @Published public var syncMessage: String?

    private let backend = MilliBackendClient.shared
    private let storageKeyBank = "milli_connected_bank_v3_plaid"
    private let storageKeyPlatforms = "milli_linked_platforms_v3"
    private let storageKeyPayouts = "milli_verified_payouts_v3"

    private init() {
        loadPersistedData()
    }

    public var totalPayoutsAmount: Double {
        payouts.reduce(0) { $0 + $1.grossAmount }
    }

    func adoptPlaidAccount(_ account: MilliPlaidAccount) {
        let balance = account.availableBalance ?? account.currentBalance ?? 0
        connectedBank = ConnectedBankAccount(
            id: "plaid_\(account.accountID)",
            institutionName: account.institutionName ?? "Connected bank",
            accountName: account.name ?? "Payout account",
            accountMask: account.mask ?? "",
            accountType: account.subtype?.capitalized ?? account.type?.capitalized ?? "Account",
            balance: balance,
            lastSyncedAt: Date(),
            // /plaid/accounts is currently a cached provider snapshot. Do not
            // relabel it LIVE unless the backend explicitly returns LIVE.
            isLive: account.dataState.caseInsensitiveCompare("LIVE") == .orderedSame
        )
    }

    func refreshConnectionFromBackend() async {
        guard backend.hasFinancialSession else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let accounts = try await backend.fetchPlaidAccounts()
            guard let payoutAccount = accounts.first(where: { $0.isPayoutSource == true }) else {
                connectedBank = nil
                syncMessage = nil
                return
            }
            adoptPlaidAccount(payoutAccount)
            syncMessage = nil
        } catch {
            syncMessage = error.localizedDescription
        }
    }

    public func syncTransactions() {
        guard backend.hasFinancialSession else {
            syncMessage = "Sign in with Apple is required before Milli can refresh banking data."
            return
        }

        isSyncing = true
        syncMessage = nil

        Task {
            defer { isSyncing = false }
            do {
                try await backend.refreshPlaidBalances()
                let accounts = try await backend.fetchPlaidAccounts()
                if let payoutAccount = accounts.first(where: { $0.isPayoutSource == true }) {
                    adoptPlaidAccount(payoutAccount)
                }
            } catch {
                syncMessage = error.localizedDescription
            }
        }
    }

    public func togglePlatform(id: String) {
        if let idx = linkedPlatforms.firstIndex(where: { $0.id == id }) {
            linkedPlatforms[idx].isConnected.toggle()
            linkedPlatforms[idx].autoSyncPayouts = linkedPlatforms[idx].isConnected
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
