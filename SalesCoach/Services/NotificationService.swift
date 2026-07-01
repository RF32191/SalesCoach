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
        let category = SalesCategory.allCases.first { $0.rawValue == lead.leadSource }
        let content = UNMutableNotificationContent()
        content.title = "Near \(lead.name)"
        content.subtitle = lead.company.isEmpty ? (category?.rawValue ?? "Pinned contact") : lead.company

        if lead.contactIntel.hasPersonalDetails {
            content.body = lead.contactIntel.notificationSnippet
        } else if !lead.aiRecommendedAction.isEmpty {
            content.body = lead.aiRecommendedAction
        } else {
            let place = lead.location.displayAddress.isEmpty ? lead.company : lead.location.displayAddress
            content.body = "Pinned location: \(place). Open Sales Coach for your contact briefing."
        }

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
