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
    let commission = CommissionService()
    let crmHub = CRMHubService()
    let office = OfficeService()
    let scripts = ScriptMakerService()
    let billingAgent = AutonomousBillingService()
    let tokenBilling = TokenBillingService()
    let revenueOS = RevenueOSDashboardService()
    let platform = PlatformFeatureService()
    let integrations = IntegrationService()
    let digitalCard = DigitalBusinessCardService()

    var nearbyLeadBriefing: Lead?

    init() {
        crm.integrations = integrations
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
        crm.defaultCommissionRate = commission.settings.defaultCommissionRate
        crm.stageChangeGate = { [weak self] stage, userId in
            guard let self else { return (true, "") }
            return StandoutCoachingService.shared.certificationAllowsStage(
                stage,
                userId: userId,
                training: self.training,
                certifications: self.certifications
            )
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
        commission.load(for: user.id)
        crmHub.load(for: user.id)
        crm.defaultCommissionRate = commission.settings.defaultCommissionRate
        office.load(for: user.id)
        office.syncFromAudit(userId: user.id, orders: audit.closedOrders)
        scripts.load(for: user.id)
        billingAgent.load(for: user.id)
        tokenBilling.load(for: user.id)
        revenueOS.load(for: user.id)
        platform.load(for: user.id)
        digitalCard.load(for: user.id, profile: user)
        teamSales.load(for: user.teamId ?? "solo")
        crm.loadTasks(for: user.id)
        Task { await calendar.requestAccess() }
        certifications.evaluate(sessions: training.sessions.filter { $0.userId == user.id })
        location.startGeofencing(for: crm.leads.filter { $0.location.pinReminderEnabled && $0.location.hasCoordinates })
        Task {
            await billingAgent.runAutonomousReview(
                userId: user.id,
                usage: subscription.usage,
                training: training,
                subscription: subscription,
                tokenBilling: tokenBilling,
                office: office
            )
        }
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

    func recordTokenCharge(feature: AIBillingFeature, tokens: Int) {
        guard let userId = auth.currentUser?.id else { return }
        tokenBilling.charge(
            feature: feature,
            tokensUsed: tokens,
            userId: userId,
            subscription: subscription,
            office: office
        )
    }
}
