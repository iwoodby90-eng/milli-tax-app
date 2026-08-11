import SwiftUI
import Combine

// MARK: - Mileage View Model

@MainActor
final class MileageViewModel: ObservableObject {
    @Published var isTracking = false
    @Published var activeTripMiles: String = "0.0 mi"
    @Published var weekMiles: Double = 226.8
    @Published var weekDeduction: Double = 149.75
    @Published var tripsCount: Int = 12
    @Published var isLoading = false

    func loadMileage() async {
        isLoading = false
    }

    func startTracking() async {
        isTracking = true
        activeTripMiles = "0.0 mi"
    }

    func stopTracking() async {
        isTracking = false
    }
}
