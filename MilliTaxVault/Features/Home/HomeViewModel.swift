import SwiftUI
import Combine

// MARK: - HomeViewModel — Drives the Home dashboard
// Production defaults are deliberately non-fabricated. Rich reference values are
// enabled only by Milli's DEBUG screenshot harness so visual QA remains useful
// without presenting demo money as live customer data.

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var availableToSpend: String = "—"
    @Published var sparklineData: [CGFloat] = []
    @Published var latestPayout: PayoutEntry = .unavailable
    @Published var taxVaultBalance: String = "—"
    @Published var taxReadyScore: Int = 0
    @Published var quarterlyTaxes: String = "—"
    @Published var quarterlyDueLabel: String = "Not calculated"
    @Published var mileage: String = "—"
    @Published var aiInsight: String = "Connect your accounts and complete setup to unlock personalized Milli insights."
    @Published var isLoading: Bool = false

    private static var isVisualFixtureMode: Bool {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo
        return processInfo.environment["MILLI_SCREENSHOT_MODE"] == "1"
            || processInfo.arguments.contains("-milliScreenshotMode")
        #else
        return false
        #endif
    }

    init() {
        loadData()
    }

    func loadData() {
        isLoading = true

        if Self.isVisualFixtureMode {
            applyVisualFixture()
        } else {
            // Production integration point. Authenticated dashboard snapshots and
            // local authoritative stores should replace these unavailable values.
            applyProductionSafeEmptyState()
        }

        isLoading = false
    }

    private func applyProductionSafeEmptyState() {
        availableToSpend = "—"
        sparklineData = []
        latestPayout = .unavailable
        taxVaultBalance = "—"
        taxReadyScore = 0
        quarterlyTaxes = "—"
        quarterlyDueLabel = "Not calculated"
        mileage = "—"
        aiInsight = "Connect your accounts and complete setup to unlock personalized Milli insights."
    }

    private func applyVisualFixture() {
        // Values intentionally mirror the approved visual references and exist
        // only in DEBUG screenshot mode.
        availableToSpend = "$8,642.31"
        sparklineData = [0.28, 0.42, 0.36, 0.51, 0.47, 0.63, 0.58, 0.72, 0.67, 0.82]
        latestPayout = .visualFixture
        taxVaultBalance = "$7,128.45"
        taxReadyScore = 82
        quarterlyTaxes = "$3,102.00"
        quarterlyDueLabel = "Due Sep 15"
        mileage = "1,247 mi"
        aiInsight = "You're on track to save $1,320 in taxes this year. Keep it up."
    }
}

// MARK: - PayoutEntry

struct PayoutEntry: Identifiable {
    let id = UUID()
    let platformName: String
    let platformAssetName: String
    let dateTime: String
    let amount: String

    static let visualFixture = PayoutEntry(
        platformName: "DoorDash",
        platformAssetName: "doordash-icon",
        dateTime: "Today, 8:24 AM",
        amount: "+$312.75"
    )

    static let unavailable = PayoutEntry(
        platformName: "No payout data",
        platformAssetName: "amazon-flex-icon",
        dateTime: "Connect an account to sync payouts",
        amount: "—"
    )

    // Compatibility for older callers while fixture usage is consolidated.
    static let placeholder = visualFixture
}
