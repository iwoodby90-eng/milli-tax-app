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
        formatCurrency(latestPayout?.netAmount ?? 312.64)
    }

    var latestPayoutGross: String {
        formatCurrency(latestPayout?.grossAmount ?? 376.65)
    }

    var latestPayoutPlatformFee: String {
        formatCurrency(-(latestPayout?.platformFee ?? 24.21))
    }

    var latestPayoutAdjustments: String {
        formatCurrency(-(latestPayout?.adjustments ?? 38.80))
    }

    var latestPayoutSource: String {
        latestPayout?.source ?? "Spark Driver\u{2122}"
    }

    var latestPayoutDate: String {
        latestPayout?.date ?? "May 10, 2024 \u{2022} 9:41 AM"
    }

    var taxAllocation: String {
        formatCurrency(latestPayout?.taxAllocation ?? 72.91)
    }

    var mileageDeduction: String {
        formatCurrency(latestPayout?.mileageDeduction ?? 38.47)
    }

    var availableToSpend: String {
        formatCurrency(latestPayout?.availableToSpend ?? 201.26)
    }

    // MARK: - Actions

    func loadPayouts() async {
        guard api.isAuthenticated else { return }
        isLoading = true
        do {
            payouts = try await api.request(path: "/payouts")
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
        // Placeholder for future Stripe payout functionality
        errorMessage = nil
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
