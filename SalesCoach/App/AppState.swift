import SwiftUI

@MainActor
@Observable
final class AppState {
    let auth = AuthService()
    let chat = ChatService()
    let training = TrainingService()
    let crm = CRMService()
    let subscription = SubscriptionService()
    let team = TeamService()
    let voice = VoiceService()
    let notifications = NotificationService()
    let location = LocationService()

    init() {
        crm.syncGeofencing = { [weak self] leads in
            self?.location.startGeofencing(for: leads)
        }
        location.leadLookup = { [weak self] leadId in
            self?.crm.leads.first { $0.id == leadId }
        }
        location.configure(notificationService: notifications)
    }

    func loadUserData() {
        guard let user = auth.currentUser else { return }
        chat.loadConversations(for: user.id)
        training.loadSessions(for: user.id)
        crm.loadLeads(for: user.id)
        if let teamId = user.teamId {
            team.loadTeam(teamId: teamId)
        }
        location.startGeofencing(for: crm.leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates })
    }

    func setupPermissions() async {
        await notifications.requestAuthorization()
        location.requestAuthorization()
        location.requestAlwaysAuthorizationIfNeeded()
    }
}
