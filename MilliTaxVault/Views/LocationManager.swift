import Foundation
import CoreLocation
import MapKit

// MARK: - LocationManager — Handles location permissions and trip recording
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    private var isRecording = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // meters
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func startTracking() {
        isRecording = true
        routeCoordinates = []
        if let current = lastLocation {
            routeCoordinates.append(current.coordinate)
        }
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        isRecording = false
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        
        if isRecording {
            routeCoordinates.append(location.coordinate)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently handle — map will show fallback Detroit location
    }
}
