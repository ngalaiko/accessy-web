import Combine
import CoreLocation
import Foundation

/// Service for tracking device location
@MainActor
class LocationService: NSObject, ObservableObject {
    // MARK: - Published State

    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isAuthorized = false

    // MARK: - Dependencies

    private let locationManager = CLLocationManager()

    // MARK: - Initialization

    override init() {
        // Initialize with default values
        authorizationStatus = .notDetermined
        isAuthorized = false

        super.init()

        // Set delegate first
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // Now check the actual status
        authorizationStatus = locationManager.authorizationStatus
        isAuthorized = locationManager.authorizationStatus == .authorizedWhenInUse
    }

    // MARK: - Public Methods

    /// Request location authorization if not determined
    func requestAuthorization() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    /// Start updating location
    func startUpdatingLocation() {
        guard isAuthorized else { return }
        locationManager.startUpdatingLocation()
    }

    /// Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    /// Calculate distance from current location to a coordinate
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                self.currentLocation = location
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            self.isAuthorized = manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways

            if self.isAuthorized {
                self.startUpdatingLocation()
            } else {
                self.stopUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        // Handle error silently - location updates will just not be available
        print("Location error: \(error.localizedDescription)")
    }
}
