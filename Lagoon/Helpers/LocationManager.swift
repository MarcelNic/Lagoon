import Foundation
import CoreLocation
import MapKit

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    var location: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLoading = false
    var error: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        isLoading = true
        error = nil
        manager.requestWhenInUseAuthorization()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            error = "Standortzugriff verweigert"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        location = loc
        reverseGeocode(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        isLoading = false
        self.error = error.localizedDescription
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(_ location: CLLocation) {
        Task { @MainActor in
            if let request = MKReverseGeocodingRequest(location: location) {
                do {
                    let mapItems = try await request.mapItems
                    if let mapItem = mapItems.first,
                       let address = mapItem.address {
                        // Use shortAddress for a compact display (e.g., "Berlin, Germany")
                        self.locationName = address.shortAddress ?? address.fullAddress
                    }
                } catch {
                    // Geocoding failed, location name stays nil
                }
            }
            self.isLoading = false
        }
    }
}
