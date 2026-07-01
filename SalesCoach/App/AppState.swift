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
    let discovery = ProspectDiscoveryService()
    let certifications = CertificationService()
    let teamGoals = TeamGoalsService()

    var nearbyLeadBriefing: Lead?

    init() {
        crm.syncGeofencing = { [weak self] leads in
            self?.location.startGeofencing(for: leads)
        }
        location.leadLookup = { [weak self] leadId in
            self?.crm.leads.first { $0.id == leadId }
        }
        location.onProximityEnter = { [weak self] lead in
            guard let self else { return }
            self.nearbyLeadBriefing = lead
            self.notifications.notifyProximity(to: lead)
        }
        location.configure(notificationService: notifications)

        OpenAIService.shared.onTokensUsed = { [weak self] tokens in
            self?.subscription.recordTokenUsage(tokens)
        }
        voice.onTokensUsed = { [weak self] tokens in
            self?.subscription.recordTokenUsage(tokens)
        }
    }

    func loadUserData() {
        guard let user = auth.currentUser else { return }
        chat.loadConversations(for: user.id)
        training.loadSessions(for: user.id)
        crm.loadLeads(for: user.id)
        if let teamId = user.teamId {
            team.loadTeam(teamId: teamId)
        }
        certifications.load(for: user.id)
        teamGoals.load(for: user.id)
        certifications.evaluate(sessions: training.sessions.filter { $0.userId == user.id })
        location.startGeofencing(for: crm.leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates })
    }

    func setupPermissions() async {
        await notifications.requestAuthorization()
        location.requestAuthorization()
        location.requestAlwaysAuthorizationIfNeeded()
        await voice.requestPermissions()
    }
}
