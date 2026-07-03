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
    let gamification = GamificationService()
    let audit = AuditService()
    let calendar = CalendarService()
    let teamSales = TeamSalesService()

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
        crm.onContactLogged = { [weak self] in
            guard let self, let userId = auth.currentUser?.id else { return }
            gamification.record(.crmContact, userId: userId)
        }
        crm.onDealWon = { [weak self] in
            guard let self, let userId = auth.currentUser?.id else { return }
            gamification.record(.dealWon, userId: userId)
        }
        crm.recordAudit = { [weak self] entry in
            guard let self, let userId = auth.currentUser?.id else { return }
            audit.append(entry, for: userId)
        }
        crm.recordClosedOrder = { [weak self] order, entry in
            guard let self, let userId = auth.currentUser?.id else { return }
            audit.recordClosedOrder(order, audit: entry, for: userId)
        }
        crm.onCalendarFollowUp = { [weak self] title, date, notes in
            self?.calendar.addFollowUpEvent(title: title, date: date, notes: notes)
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
        gamification.load(for: user.id)
        audit.load(for: user.id)
        teamSales.load(for: user.teamId ?? "solo")
        crm.loadTasks(for: user.id)
        Task { await calendar.requestAccess() }
        certifications.evaluate(sessions: training.sessions.filter { $0.userId == user.id })
        location.startGeofencing(for: crm.leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates })
    }

    func loadExampleData() {
        guard let user = auth.currentUser else { return }
        crm.loadExampleLeads(for: user.id)
        teamGoals.loadExampleContent(for: user.id)
        if let teamId = user.teamId {
            team.loadExampleTeam(teamId: teamId)
        }
    }

    func removeExampleData() {
        guard let user = auth.currentUser else { return }
        crm.removeExampleLeads(for: user.id)
        teamGoals.clearExampleContent(for: user.id)
        if let teamId = user.teamId {
            team.removeExampleTeamMembers(teamId: teamId)
        }
    }

    func clearAllLocalCRMData() {
        guard let user = auth.currentUser else { return }
        crm.clearAllLeads(for: user.id)
        audit.clear(for: user.id)
    }

    func setupPermissions() async {
        await notifications.requestAuthorization()
        location.requestAuthorization()
        location.requestAlwaysAuthorizationIfNeeded()
        await voice.requestPermissions()
    }
}
