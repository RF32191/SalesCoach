import CoreLocation
import MapKit
import UIKit

@MainActor
@Observable
final class LocationService: NSObject {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentCoordinate: CLLocationCoordinate2D?
    var errorMessage: String?

    var leadLookup: ((String) -> Lead?)?
    var onProximityEnter: ((Lead) -> Void)?
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    private var locationTimeoutTask: Task<Void, Never>?
    private var awaitingAuthorizationForLocation = false
    private weak var notificationService: NotificationService?
    private var monitoredLeadIds: Set<String> = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 75
        authorizationStatus = manager.authorizationStatus
    }

    func configure(notificationService: NotificationService) {
        self.notificationService = notificationService
    }

    var isLocationAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var locationStatusMessage: String {
        switch authorizationStatus {
        case .notDetermined: "Location needed to find nearby companies"
        case .restricted, .denied: "Enable location in Settings to search nearby businesses"
        case .authorizedWhenInUse, .authorizedAlways: currentAddressLabel ?? "Current location locked"
        @unknown default: "Location unavailable"
        }
    }

    var currentAddressLabel: String?

    func requestAuthorization() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func openSettingsIfNeeded() {
        #if os(iOS)
        guard authorizationStatus == .denied || authorizationStatus == .restricted,
              let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }

    func ensureCurrentLocation() async -> CLLocationCoordinate2D? {
        if let coordinate = currentCoordinate {
            return coordinate
        }

        if authorizationStatus == .denied || authorizationStatus == .restricted {
            errorMessage = "Allow location access to search companies near you."
            return nil
        }

        return await requestCurrentLocation()
    }

    func requestAlwaysAuthorizationIfNeeded() {
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        if let coordinate = currentCoordinate {
            return coordinate
        }

        if authorizationStatus == .denied || authorizationStatus == .restricted {
            errorMessage = "Location access is required to pin leads."
            return nil
        }

        return await withCheckedContinuation { continuation in
            resumePendingLocation(with: nil, keepWaiting: false)

            locationContinuation = continuation
            locationTimeoutTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(12))
                if locationContinuation != nil {
                    resumePendingLocation(with: currentCoordinate)
                }
            }

            switch authorizationStatus {
            case .notDetermined:
                awaitingAuthorizationForLocation = true
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                resumePendingLocation(with: nil)
            }
        }
    }

    func reverseGeocode(coordinate: CLLocationCoordinate2D) async -> LeadLocation? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location),
              let placemark = placemarks.first else {
            return LeadLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        return LeadLocation(
            address: [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " "),
            city: [placemark.locality, placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", "),
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    func startGeofencing(for leads: [Lead]) {
        manager.monitoredRegions.forEach { manager.stopMonitoring(for: $0) }
        monitoredLeadIds.removeAll()

        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            return
        }

        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { return }

        for lead in leads where lead.location.pinReminderEnabled && lead.location.hasCoordinates {
            guard let lat = lead.location.latitude, let lon = lead.location.longitude else { continue }
            let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let region = CLCircularRegion(
                center: center,
                radius: min(max(lead.location.reminderRadiusMeters, 100), 1000),
                identifier: lead.id
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            manager.startMonitoring(for: region)
            monitoredLeadIds.insert(lead.id)
        }

        manager.startUpdatingLocation()
    }

    private func resumePendingLocation(with coordinate: CLLocationCoordinate2D?, keepWaiting: Bool = false) {
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil

        if !keepWaiting {
            locationContinuation?.resume(returning: coordinate)
            locationContinuation = nil
            awaitingAuthorizationForLocation = false
        }
    }

    private func finishLocationRequest(with coordinate: CLLocationCoordinate2D?) {
        if let coordinate {
            currentCoordinate = coordinate
        }
        resumePendingLocation(with: coordinate ?? currentCoordinate)
    }

    private func beginSingleLocationUpdate() {
        guard isLocationAuthorized else {
            finishLocationRequest(with: nil)
            return
        }
        manager.requestLocation()
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            if isLocationAuthorized {
                if awaitingAuthorizationForLocation || locationContinuation != nil {
                    beginSingleLocationUpdate()
                }
            } else if authorizationStatus == .denied || authorizationStatus == .restricted {
                errorMessage = "Allow location access to search companies near you."
                finishLocationRequest(with: nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let coordinate = locations.last?.coordinate else { return }
            currentCoordinate = coordinate
            finishLocationRequest(with: coordinate)

            if let geo = await reverseGeocode(coordinate: coordinate) {
                currentAddressLabel = geo.displayAddress.isEmpty ? nil : geo.displayAddress
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError, clError.code == .locationUnknown, locationContinuation != nil {
                return
            }
            errorMessage = error.localizedDescription
            finishLocationRequest(with: currentCoordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            if let lead = leadLookup?(region.identifier) {
                onProximityEnter?(lead)
            } else {
                notificationService?.scheduleGeofenceReminder(leadId: region.identifier)
            }
        }
    }
}
