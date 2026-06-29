import CoreLocation
import Foundation

@MainActor
@Observable
final class LocationGeofenceService: NSObject {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentLocation: CLLocation?
    var nearbyLeadIds: Set<String> = []
    var errorMessage: String?

    private let manager = CLLocationManager()
    private var monitoredLeadIds: Set<String> = []
    private weak var crmService: CRMService?
    private weak var notificationService: NotificationService?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = true
        authorizationStatus = manager.authorizationStatus
    }

    func configure(crm: CRMService, notifications: NotificationService) {
        crmService = crm
        notificationService = notifications
    }

    func requestPermissions() async {
        manager.requestWhenInUseAuthorization()
        try? await Task.sleep(for: .milliseconds(500))
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
    }

    func startMonitoring(leads: [Lead]) {
        stopMonitoring()
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            errorMessage = "Geofencing is not available on this device."
            return
        }

        for lead in leads where lead.location.pinReminderEnabled && lead.location.hasCoordinates {
            guard let coordinate = lead.location.coordinate else { continue }
            let region = CLCircularRegion(
                center: coordinate,
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

    func stopMonitoring() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        monitoredLeadIds.removeAll()
        manager.stopUpdatingLocation()
    }

    func syncRegions(with leads: [Lead]) {
        startMonitoring(leads: leads.filter { $0.location.pinReminderEnabled })
    }

    private func lead(for id: String) -> Lead? {
        crmService?.leads.first { $0.id == id }
    }

    private func handleEntry(for leadId: String) {
        guard let lead = lead(for: leadId), !nearbyLeadIds.contains(leadId) else { return }
        nearbyLeadIds.insert(leadId)
        notificationService?.notifyProximity(to: lead)
    }
}

extension LocationGeofenceService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                if let leads = crmService?.leads {
                    syncRegions(with: leads)
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            guard let leads = crmService?.leads else { return }

            for lead in leads where lead.location.pinReminderEnabled && lead.location.hasCoordinates {
                guard let coordinate = lead.location.coordinate else { continue }
                let leadLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let distance = location.distance(from: leadLocation)
                if distance <= lead.location.reminderRadiusMeters {
                    handleEntry(for: lead.id)
                } else {
                    nearbyLeadIds.remove(lead.id)
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            handleEntry(for: region.identifier)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            nearbyLeadIds.remove(region.identifier)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
