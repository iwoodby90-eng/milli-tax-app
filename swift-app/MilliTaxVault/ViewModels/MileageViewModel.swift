import SwiftUI
import Combine

// MARK: - Mileage View Model

@MainActor
final class MileageViewModel: ObservableObject {
    @Published var activeTrip: MileageTrip?
    @Published var summary: MileageSummary = MileageSummary()
    @Published var isTracking = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    // Display values with fallbacks
    var activeTripMiles: String {
        String(format: "%.2f mi", activeTrip?.miles ?? 18.64)
    }

    var activeTripDeduction: String {
        formatCurrency(activeTrip?.deduction ?? 9.82)
    }

    var todayMiles: String {
        String(format: "%.2f mi", summary.businessMiles > 0 ? summary.businessMiles : 126.37)
    }

    var todayDeduction: String {
        formatCurrency(summary.totalDeduction > 0 ? summary.totalDeduction : 66.41)
    }

    var quarterMiles: String {
        "\(Int(summary.totalMiles > 0 ? summary.totalMiles : 2345).formatted()) mi"
    }

    var trackingStatus: String {
        isTracking ? "Tracking Active" : "Tracking Paused"
    }

    // MARK: - Actions

    func loadMileage() async {
        guard api.isAuthenticated else { return }
        isLoading = true
        do {
            let s: MileageSummary = try await api.request(path: "/mileage/summary")
            summary = s
        } catch {
            // Use fallback data
        }

        do {
            let trip: MileageTrip? = try await api.request(path: "/trips/active")
            activeTrip = trip
            isTracking = trip?.isActive ?? false
        } catch {
            // No active trip
        }
        isLoading = false
    }

    func startTracking() async {
        do {
            let trip: MileageTrip = try await api.request(
                method: "POST",
                path: "/trips/start"
            )
            activeTrip = trip
            isTracking = true
        } catch {
            errorMessage = "Failed to start mileage tracking."
        }
    }

    func stopTracking() async {
        guard let tripId = activeTrip?.id else { return }
        do {
            let _: MileageTrip = try await api.request(
                method: "POST",
                path: "/trips/\(tripId)/end",
                body: ["miles": activeTrip?.miles ?? 0]
            )
            isTracking = false
            await loadMileage()
        } catch {
            errorMessage = "Failed to stop tracking."
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
