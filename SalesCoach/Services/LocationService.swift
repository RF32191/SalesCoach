import CoreLocation
import MapKit

@MainActor
@Observable
final class LocationService: NSObject {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentCoordinate: CLLocationCoordinate2D?
    var errorMessage: String?

    var leadLookup: ((String) -> Lead?)?
    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
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

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorizationIfNeeded() {
        if authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled."
            return nil
        }

        if authorizationStatus == .notDetermined {
            requestAuthorization()
        }

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            errorMessage = "Location access is required to pin leads."
            return nil
        }

        manager.requestLocation()

        return await withCheckedContinuation { continuation in
            locationContinuation = continuation
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
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            let coordinate = locations.last?.coordinate
            currentCoordinate = coordinate
            locationContinuation?.resume(returning: coordinate)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            if let lead = leadLookup?(region.identifier) {
                notificationService?.notifyProximity(to: lead)
            } else {
                notificationService?.scheduleGeofenceReminder(leadId: region.identifier)
            }
        }
    }
}
