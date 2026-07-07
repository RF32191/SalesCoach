import SwiftUI

struct ScriptMakerView: View {
    @Environment(AppState.self) private var appState
    @State private var scriptType: ScriptType = .coldCall
    @State private var selectedLeadId: String?
    @State private var customPrompt = ""
    @State private var generatedBody = ""
    @State private var title = ""
    @State private var isGenerating = false
    @State private var tokenLimitMessage = ""

    private var userId: String { appState.auth.currentUser?.id ?? "" }
    private var selectedLead: Lead? {
        guard let id = selectedLeadId else { return appState.crm.leads.first }
        return appState.crm.leads.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "AI Script Maker",
                    subtitle: "Generate talk tracks for calls, emails, voicemails, and objections",
                    icon: "text.book.closed.fill",
                    accent: AppTheme.electricBlueBright
                )

                Picker("Script Type", selection: $scriptType) {
                    ForEach(ScriptType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                if !appState.crm.leads.isEmpty {
                    Picker("For Client", selection: Binding(
                        get: { selectedLeadId ?? appState.crm.leads.first?.id ?? "" },
                        set: { selectedLeadId = $0 }
                    )) {
                        ForEach(appState.crm.leads) { lead in
                            Text(lead.company.isEmpty ? lead.name : lead.company).tag(lead.id)
                        }
                    }
                }

                TextField("Custom angle (optional)", text: $customPrompt, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(AppTextFieldStyle())

                PrimaryButton(title: isGenerating ? "Generating..." : "Generate Script", icon: "sparkles") {
                    Task { await generate() }
                }
                .disabled(isGenerating)

                if !tokenLimitMessage.isEmpty {
                    Text(tokenLimitMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.dangerRed)
                }

                TextField("Script title", text: $title)
                    .textFieldStyle(AppTextFieldStyle())

                TextField("Script body", text: $generatedBody, axis: .vertical)
                    .lineLimit(8...24)
                    .textFieldStyle(AppTextFieldStyle())

                if !generatedBody.isEmpty {
                    HStack(spacing: 10) {
                        PrimaryButton(title: "Save Script", icon: "square.and.arrow.down") { saveScript() }
                        ShareLink(item: generatedBody) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }

                SectionHeader(title: "Saved Scripts")
                ForEach(appState.scripts.scripts) { script in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(script.title).font(.headline)
                        Text(script.scriptType.rawValue).font(.caption).foregroundStyle(AppTheme.textMuted)
                        Text(script.body).font(.caption).foregroundStyle(AppTheme.textSecondary).lineLimit(4)
                    }
                    .cardStyle()
                    .onTapGesture {
                        generatedBody = script.body
                        title = script.title
                        scriptType = script.scriptType
                    }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Script Maker")
        .onAppear { appState.scripts.load(for: userId) }
    }

    private func generate() async {
        isGenerating = true
        tokenLimitMessage = ""
        guard appState.tokenBilling.canUseFeature(.scriptGeneration, subscription: appState.subscription) else {
            tokenLimitMessage = "AI token limit reached. Upgrade your plan or wait for monthly reset."
            isGenerating = false
            return
        }
        if let draft = await appState.scripts.generateScript(
            type: scriptType,
            lead: selectedLead,
            category: appState.auth.currentUser?.salesCategory,
            customPrompt: customPrompt
        ) {
            generatedBody = draft.body
            title = draft.title
            appState.recordTokenCharge(feature: .scriptGeneration, tokens: AIBillingFeature.scriptGeneration.estimatedTokens)
        }
        isGenerating = false
    }

    private func saveScript() {
        guard !generatedBody.isEmpty else { return }
        let script = SalesScript(
            userId: userId,
            title: title.isEmpty ? scriptType.rawValue : title,
            scriptType: scriptType,
            leadId: selectedLead?.id,
            body: generatedBody
        )
        appState.scripts.save(script, for: userId)
        Haptic.success()
    }
}

struct RepDNAView: View {
    @Environment(AppState.self) private var appState
    private var userId: String { appState.auth.currentUser?.id ?? "" }
    private var profile: RepDNAProfile {
        RepDNAService.shared.profile(
            userId: userId,
            training: appState.training,
            crm: appState.crm,
            gamification: appState.gamification
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Rep DNA",
                    subtitle: profile.headline,
                    icon: "person.crop.circle.badge.checkmark",
                    accent: AppTheme.tealGreen
                )

                HStack(spacing: 12) {
                    skillPill("Strongest", profile.strongestSkill, AppTheme.successGreen)
                    skillPill("Focus Area", profile.weakestSkill, AppTheme.warningOrange)
                }

                SectionHeader(title: "Skill Profile")
                ForEach(profile.skills) { skill in
                    CategoryScoreBar(category: ScoreCategory(name: skill.name, score: skill.score))
                }

                NavigationLink {
                    VoiceRoleplaySetupView(preselectedScenario: profile.dailyDrillScenario)
                } label: {
                    FeatureCard(
                        title: profile.dailyDrillTitle,
                        subtitle: "5-minute drill assigned from your skill gaps",
                        icon: "mic.fill",
                        accentColor: AppTheme.electricBlueBright
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Weekly Challenge")
                    Text(profile.weeklyChallenge.progressText)
                        .font(.subheadline.bold())
                    ProgressView(
                        value: Double(profile.weeklyChallenge.contactsDone + profile.weeklyChallenge.roleplaysDone),
                        total: Double(profile.weeklyChallenge.contactsTarget + profile.weeklyChallenge.roleplaysTarget)
                    )
                    .tint(AppTheme.tealGreen)
                }
                .cardStyle()
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Rep DNA")
    }

    private func skillPill(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(AppTheme.textMuted)
            Text(value).font(.caption.bold()).foregroundStyle(color).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DealReplayView: View {
    @Environment(AppState.self) private var appState
    let lead: Lead

    private var events: [DealReplayEvent] {
        StandoutCoachingService.shared.dealReplay(for: lead, audit: appState.audit)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                CRMGradientHeader(
                    title: "Deal Replay",
                    subtitle: "\(lead.name) · \(lead.dealStage.rawValue)",
                    icon: "play.circle.fill",
                    accent: AppTheme.electricBlueBright
                )

                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: event.icon)
                            .foregroundStyle(AppTheme.electricBlueBright)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(event.title).font(.subheadline.bold())
                            Text(event.detail).font(.caption).foregroundStyle(AppTheme.textSecondary)
                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(AppTheme.textMuted)
                            if let tip = event.coachingTip {
                                Text(tip).font(.caption.bold()).foregroundStyle(AppTheme.tealGreen)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Deal Replay")
    }
}

struct WalkInModeView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedLead: Lead?
    @State private var visitNotes = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Walk-In Mode")
                .font(.title2.bold())
            Text("Minimal UI for door-to-door and in-person visits")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            Picker("Client", selection: Binding(
                get: { selectedLead?.id ?? appState.crm.leads.first?.id ?? "" },
                set: { id in selectedLead = appState.crm.leads.first { $0.id == id } }
            )) {
                ForEach(appState.crm.leads) { lead in
                    Text(lead.name).tag(lead.id)
                }
            }

            if let lead = selectedLead ?? appState.crm.leads.first {
                LeadContactLinkRow(lead: lead, compact: false)
                PrimaryButton(title: "Log Visit", icon: "figure.walk") {
                    appState.crm.logContact(for: lead.id, type: .visit, summary: "Walk-in visit logged")
                    Haptic.success()
                }
                NavigationLink {
                    VoiceRoleplaySetupView(
                        preselectedScenario: .doorToDoor,
                        practiceLead: lead
                    )
                } label: {
                    Label("Practice If They Say No", systemImage: "mic.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.warningOrange.opacity(0.15))
                        .foregroundStyle(AppTheme.warningOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding()
        .appBackground()
        .navigationTitle("Walk-In")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ManagerMorningBriefView: View {
    @Environment(AppState.self) private var appState
    @State private var brief: ManagerMorningBrief?
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Manager Morning Brief",
                    subtitle: "AI coaching digest for your team",
                    icon: "sun.max.fill",
                    accent: AppTheme.warningOrange
                )

                PrimaryButton(title: isLoading ? "Generating..." : "Generate Brief", icon: "sparkles") {
                    Task { await loadBrief() }
                }
                .disabled(isLoading)

                if let brief {
                    reportSection("Headline", [brief.headline])
                    reportSection("Rep Highlights", brief.repHighlights)
                    reportSection("Coaching Assignments", brief.coachingAssignments)
                    reportSection("Pipeline Alerts", brief.pipelineAlerts)
                    reportSection("Team Wins", brief.teamWins)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Manager Brief")
    }

    private func reportSection(_ title: String, _ items: [String]) -> some View {
        ReportSection(title: title, icon: "doc.text.fill", items: items)
    }

    private func loadBrief() async {
        isLoading = true
        brief = await StandoutCoachingService.shared.managerBrief(
            crm: appState.crm,
            training: appState.training,
            teamSales: appState.teamSales,
            teamId: appState.auth.currentUser?.teamId ?? "solo",
            userId: appState.auth.currentUser?.id ?? ""
        )
        isLoading = false
    }
}

struct SmartRouteCoachingView: View {
    @Environment(AppState.self) private var appState
    private var userId: String { appState.auth.currentUser?.id ?? "" }

    private var stops: [SmartRouteStop] {
        let profile = RepDNAService.shared.profile(
            userId: userId,
            training: appState.training,
            crm: appState.crm,
            gamification: appState.gamification
        )
        return StandoutCoachingService.shared.smartRoute(
            from: appState.location.currentCoordinate,
            leads: appState.crm.leads,
            weakestSkill: profile.weakestSkill
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                CRMGradientHeader(
                    title: "Smart Route + Coaching",
                    subtitle: "Optimized stops with pre-visit coaching notes",
                    icon: "map.fill",
                    accent: AppTheme.tealGreen
                )

                ForEach(stops) { stop in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Stop \(stop.order)").font(.caption.bold()).foregroundStyle(AppTheme.tealGreen)
                            Spacer()
                            Text(stop.lead.company.isEmpty ? stop.lead.name : stop.lead.company)
                                .font(.headline)
                        }
                        Text(stop.coachingNote)
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.electricBlueBright)
                        if stop.lead.location.hasCoordinates,
                           let lat = stop.lead.location.latitude,
                           let lon = stop.lead.location.longitude {
                            AppleMapsNavigateButton(
                                title: "Navigate",
                                name: stop.lead.name,
                                latitude: lat,
                                longitude: lon,
                                origin: appState.location.currentCoordinate,
                                style: .compact
                            )
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Smart Route")
    }
}

struct CommissionSimulatorSection: View {
    @Environment(AppState.self) private var appState
    let lead: Lead
    @State private var dealValue: Double
    @State private var discountPercent: Double = 0

    init(lead: Lead) {
        self.lead = lead
        _dealValue = State(initialValue: lead.dealValue)
    }

    private var commission: Double {
        dealValue * (1 - discountPercent / 100) * appState.commission.settings.defaultCommissionRate
    }

    private var quotaProgress: Double {
        let userId = appState.auth.currentUser?.id ?? ""
        let current = appState.commission.revenueThisMonth(orders: appState.audit.closedOrders, userId: userId)
        let target = appState.commission.settings.monthlyRevenueTarget
        guard target > 0 else { return 0 }
        return min(1, (current + dealValue) / target)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Commission Simulator")
            Text("Deal value: $\(Int(dealValue))")
            Slider(value: $dealValue, in: 0...max(lead.dealValue * 2, 1000), step: 100)
            Text("Discount: \(Int(discountPercent))%")
            Slider(value: $discountPercent, in: 0...30, step: 1)
            HStack {
                VStack(alignment: .leading) {
                    Text("Your commission").font(.caption).foregroundStyle(AppTheme.textMuted)
                    Text("$\(Int(commission))").font(.title3.bold()).foregroundStyle(AppTheme.successGreen)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Quota if closed").font(.caption).foregroundStyle(AppTheme.textMuted)
                    Text("\(Int(quotaProgress * 100))%").font(.title3.bold()).foregroundStyle(AppTheme.tealGreen)
                }
            }
        }
        .cardStyle()
    }
}

struct StandoutFeaturesHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SectionHeader(title: "Coaching Loop")
                hubLink("Rep DNA", "Skill profile + daily drill", "person.crop.circle.badge.checkmark") { RepDNAView() }
                hubLink("Script Maker", "AI talk tracks", "text.book.closed.fill") { ScriptMakerView() }
                hubLink("Smart Route", "Coaching at each stop", "map.fill") { SmartRouteCoachingView() }
                hubLink("Walk-In Mode", "Field visit quick actions", "figure.walk") { WalkInModeView() }
                hubLink("Manager Brief", "AI team digest", "sun.max.fill") { ManagerMorningBriefView() }
                hubLink("Commission Calculator", "Payouts, splits, quota", "function") { CommissionCalculatorView() }
                hubLink("Activity Log", "Training + chat history", "clock.arrow.circlepath") { ConversationTrainingLogView() }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Coaching Toolkit")
    }

    private func hubLink<D: View>(_ title: String, _ subtitle: String, _ icon: String, @ViewBuilder _ dest: () -> D) -> some View {
        NavigationLink { dest() } label: {
            FeatureCard(title: title, subtitle: subtitle, icon: icon, accentColor: AppTheme.electricBlueBright)
        }
        .buttonStyle(.plain)
    }
}
