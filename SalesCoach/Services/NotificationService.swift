import UserNotifications

@MainActor
@Observable
final class NotificationService {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        authorizationStatus = granted ? .authorized : .denied
        if !granted {
            authorizationStatus = await center.notificationSettings().authorizationStatus
        }
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func scheduleGeofenceReminder(leadId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Nearby Lead Reminder"
        content.body = "You're near a pinned lead. Tap to review details and follow up."
        content.sound = .default
        content.userInfo = ["leadId": leadId]

        let request = UNNotificationRequest(
            identifier: "geofence-\(leadId)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    func notifyProximity(to lead: Lead) {
        let content = UNMutableNotificationContent()
        content.title = "You're near \(lead.name)"
        let place = lead.location.displayAddress.isEmpty ? lead.company : lead.location.displayAddress
        content.body = "Pinned location: \(place). Follow up while you're nearby."
        content.sound = .default
        content.userInfo = ["leadId": lead.id]

        let request = UNNotificationRequest(
            identifier: "proximity-\(lead.id)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
