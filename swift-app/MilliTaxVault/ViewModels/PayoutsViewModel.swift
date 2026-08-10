import SwiftUI

// MARK: - Payouts View Model

@MainActor
final class PayoutsViewModel: ObservableObject {
    @Published var payouts: [Payout] = []
    @Published var latestPayout: Payout?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var subscriptionTier: String = "free"

    private let api = APIService.shared
    private let stripe = StripeService.shared

    // Formatted latest payout values with fallbacks
    var latestPayoutNet: String {
        formatCurrency(latestPayout?.amount ?? 312.64)
    }

    var latestPayoutGross: String {
        formatCurrency(latestPayout?.amount ?? 376.65)
    }

    var latestPayoutPlatformFee: String {
        formatCurrency(0)
    }

    var latestPayoutAdjustments: String {
        formatCurrency(0)
    }

    var latestPayoutSource: String {
        latestPayout?.source ?? "Spark Driver\u{2122}"
    }

    var latestPayoutDate: String {
        latestPayout?.date ?? "May 10, 2024 \u{2022} 9:41 AM"
    }

    var taxAllocation: String {
        formatCurrency(latestPayout?.savingsSetAside ?? 72.91)
    }

    var mileageDeduction: String {
        formatCurrency(0)
    }

    var availableToSpend: String {
        let amt = (latestPayout?.amount ?? 312.64) - (latestPayout?.savingsSetAside ?? 72.91)
        return formatCurrency(amt)
    }

    // MARK: - Actions

    func loadPayouts() async {
        guard api.isAuthenticated else { return }
        isLoading = true
        do {
            payouts = try await api.request(path: "/deposits")
            latestPayout = payouts.first
        } catch {
            // Use fallback data
        }

        // Also check subscription status for Stripe integration
        do {
            let status = try await stripe.getSubscriptionStatus()
            subscriptionTier = status.tier
        } catch {
            // Keep default tier
        }
        isLoading = false
    }

    func requestPayout() async {
        errorMessage = nil
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
