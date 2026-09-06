import Foundation
import CoreLocation
import MapKit

// MARK: - LocationManager
// Production mileage-tracking state for the native SwiftUI app. Tracking is
// explicitly user-controlled; background delivery is enabled only while an
// active trip is being recorded.

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let dailyDistanceKey = "milli_mileage_daily_distance_meters"
    private let dailyDateKey = "milli_mileage_daily_distance_date"

    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isTracking = false
    @Published private(set) var distanceMeters: CLLocationDistance = 0
    @Published private(set) var tripStartedAt: Date?
    @Published private(set) var completedTodayDistanceMeters: CLLocationDistance = 0
    @Published var errorMessage: String?

    private var previousRecordedLocation: CLLocation?
    private var shouldStartAfterAuthorization = false

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 8
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = true
        manager.showsBackgroundLocationIndicator = true

        authorizationStatus = manager.authorizationStatus
        loadDailyDistance()
    }

    var distanceMiles: Double {
        distanceMeters / 1_609.344
    }

    var todayDistanceMiles: Double {
        let liveDistance = isTracking ? distanceMeters : 0
        return (completedTodayDistanceMeters + liveDistance) / 1_609.344
    }

    var canTrackLocation: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var hasAlwaysAuthorization: Bool {
        authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access is disabled. Enable location access in Settings to track deductible miles."
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            break
        }
    }

    /// Refreshes the MapKit viewport with the user's current position when Milli
    /// already has location permission. This never triggers a permission prompt.
    func refreshCurrentLocation() {
        guard canTrackLocation, !isTracking else { return }
        manager.requestLocation()
    }

    /// Requests the stronger authorization needed for the most reliable
    /// background mileage experience. iOS only presents this upgrade after the
    /// user has already granted When In Use access.
    func requestBackgroundPermission() {
        switch authorizationStatus {
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            break
        case .denied, .restricted:
            errorMessage = "Background location access is disabled in Settings."
        @unknown default:
            break
        }
    }

    func startTracking() {
        guard !isTracking else { return }

        guard canTrackLocation else {
            shouldStartAfterAuthorization = true
            requestPermission()
            return
        }

        beginTrip()
    }

    func stopTracking() {
        guard isTracking else { return }

        isTracking = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false

        if distanceMeters > 0 {
            completedTodayDistanceMeters += distanceMeters
            persistDailyDistance()
        }

        previousRecordedLocation = nil
        tripStartedAt = nil
    }

    func resetCurrentTrip() {
        guard !isTracking else { return }
        distanceMeters = 0
        routeCoordinates = []
        previousRecordedLocation = nil
    }

    private func beginTrip() {
        refreshDailyDistanceIfNeeded()

        errorMessage = nil
        distanceMeters = 0
        routeCoordinates = []
        previousRecordedLocation = nil
        tripStartedAt = Date()
        isTracking = true

        // The target includes the `location` background mode. Limit background
        // delivery to an explicit active trip rather than continuously tracking.
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location

        guard isTracking, isUsable(location) else { return }

        if let previousRecordedLocation {
            let segment = location.distance(from: previousRecordedLocation)

            // Reject GPS jitter and improbable jumps. A valid automotive sample
            // can still cover a meaningful distance between callbacks.
            if segment >= 3, segment <= 2_000 {
                distanceMeters += segment
            }
        }

        previousRecordedLocation = location
        routeCoordinates.append(location.coordinate)

        // Keep route rendering bounded during long workdays without affecting
        // the authoritative accumulated distance.
        if routeCoordinates.count > 2_500 {
            routeCoordinates.removeFirst(routeCoordinates.count - 2_500)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            if shouldStartAfterAuthorization {
                shouldStartAfterAuthorization = false
                beginTrip()
            }
        case .denied, .restricted:
            shouldStartAfterAuthorization = false
            if isTracking {
                stopTracking()
            }
            errorMessage = "Milli needs location access to record deductible mileage."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let locationError = error as? CLError, locationError.code == .locationUnknown {
            return
        }

        errorMessage = "Mileage tracking temporarily lost GPS. Milli will continue when location updates resume."
    }

    private func isUsable(_ location: CLLocation) -> Bool {
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= 65,
              abs(location.timestamp.timeIntervalSinceNow) < 20
        else {
            return false
        }

        return true
    }

    // MARK: - Daily persistence

    private func loadDailyDistance() {
        let defaults = UserDefaults.standard
        guard let storedDate = defaults.object(forKey: dailyDateKey) as? Date,
              Calendar.current.isDateInToday(storedDate)
        else {
            completedTodayDistanceMeters = 0
            persistDailyDistance()
            return
        }

        completedTodayDistanceMeters = defaults.double(forKey: dailyDistanceKey)
    }

    private func refreshDailyDistanceIfNeeded() {
        let defaults = UserDefaults.standard
        guard let storedDate = defaults.object(forKey: dailyDateKey) as? Date,
              Calendar.current.isDateInToday(storedDate)
        else {
            completedTodayDistanceMeters = 0
            persistDailyDistance()
            return
        }
    }

    private func persistDailyDistance() {
        let defaults = UserDefaults.standard
        defaults.set(completedTodayDistanceMeters, forKey: dailyDistanceKey)
        defaults.set(Date(), forKey: dailyDateKey)
    }
}

// MARK: - Shared navigation helpers

/// Business-mileage rate used by the live navigation cockpit. The existing
/// mileage screen keeps its file-local rate helper so this change does not alter
/// its established behavior.
enum NavigationMileageRate {
    static func businessRate(for date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)

        guard components.year == 2026 else {
            return 0.76
        }

        if let month = components.month, month >= 7 {
            return 0.76
        }
        return 0.725
    }
}
