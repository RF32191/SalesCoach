import SwiftUI

// MARK: - Win / Loss Autopsy

struct WinLossAutopsyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    let autopsy: WinLossAutopsy
    let lead: Lead

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(autopsy.headline)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))

                autopsySection("What Worked", autopsy.whatWorked, AppTheme.successGreen)
                autopsySection("Improve Next Time", autopsy.whatToImprove, AppTheme.warningOrange)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Team Playbook Snippet").font(.caption.bold()).foregroundStyle(AppTheme.textMuted)
                    Text(autopsy.playbookSnippet).font(.subheadline).foregroundStyle(AppTheme.primaryText(for: colorScheme))
                }
                .cardStyle()

                PrimaryButton(title: "Save to Team Playbooks", icon: "books.vertical.fill") {
                    appState.teamGoals.playbooks.insert(
                        PlaybookEntry(title: "Win: \(lead.company.isEmpty ? lead.name : lead.company)", content: autopsy.playbookSnippet, category: lead.leadSource),
                        at: 0
                    )
                    if let userId = appState.auth.currentUser?.id {
                        appState.teamGoals.save(for: userId)
                    }
                    Haptic.success()
                }

                NavigationLink {
                    VoiceRoleplaySetupView(
                        preselectedScenario: .objectionHandling,
                        preselectedPersonality: DealCoachingService.shared.personalityForLead(lead),
                        practiceLead: lead
                    )
                } label: {
                    Label(autopsy.recommendedDrill, systemImage: "mic.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(AppTheme.electricBlueBright)
                        .background(AppTheme.electricBlueBright.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)

                ForEach(autopsy.nextActions, id: \.self) { action in
                    Label(action, systemImage: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Deal Autopsy")
    }

    private func autopsySection(_ title: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle.fill").font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Objection Intelligence

struct ObjectionIntelligenceView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private var stats: [ObjectionStat] {
        CoachingIntelligenceService.shared.objectionStats(from: appState.crm.leads)
    }

    var body: some View {
        List {
            if stats.isEmpty {
                EmptyStateView(icon: "exclamationmark.bubble", title: "No objection tags yet", message: "Add objection tags on client records to build team intelligence.")
                    .listRowBackground(Color.clear)
            } else {
                ForEach(stats) { stat in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(stat.objection).font(.headline)
                            Spacer()
                            Text("\(stat.count)×").font(.caption.bold()).foregroundStyle(AppTheme.warningOrange)
                        }
                        Text("Win rate when tagged: \(Int(stat.winRate))%")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                        Text(stat.suggestedResponse)
                            .font(.caption)
                            .foregroundStyle(AppTheme.tealGreen)
                        NavigationLink {
                            VoiceRoleplaySetupView(preselectedScenario: .objectionHandling, preselectedPersonality: .skeptical)
                        } label: {
                            Label("Practice response", systemImage: "mic.fill")
                                .font(.caption.bold())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Objection Intel")
    }
}

struct BattleCardsView: View {
    @Environment(AppState.self) private var appState
    @State private var competitor = ""

    private var card: BattleCard {
        CoachingIntelligenceService.shared.battleCard(
            for: competitor,
            category: appState.auth.currentUser?.salesCategory
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TextField("Competitor name", text: $competitor)
                    .textFieldStyle(AppTextFieldStyle())

                if !competitor.isEmpty {
                    battleSection("Their Strengths", card.strengths, AppTheme.dangerRed)
                    battleSection("Their Weaknesses", card.weaknesses, AppTheme.successGreen)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Talk Track").font(.headline)
                        Text(card.talkTrack).font(.subheadline)
                    }
                    .cardStyle()
                    ForEach(card.proofPoints, id: \.self) { Label($0, systemImage: "star.fill").font(.caption) }
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Battle Cards")
    }

    private func battleSection(_ title: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.bold()).foregroundStyle(color)
            ForEach(items, id: \.self) { Text("• \($0)").font(.caption) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Voice Log

struct VoiceLogView: View {
    @Environment(AppState.self) private var appState
    @State private var transcript = ""
    @State private var isRecording = false
    @State private var parseResult: VoiceLogParseResult?

    var initialTranscript: String = ""
    var autoSave: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMGradientHeader(
                    title: "Voice Activity Log",
                    subtitle: "Speak naturally — we'll match the client and log the activity.",
                    icon: "waveform.circle.fill",
                    accent: AppTheme.electricBlueBright
                )

                TextField("Or type: Called Acme, interested, follow up Friday...", text: $transcript, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(AppTextFieldStyle())

                PrimaryButton(title: isRecording ? "Listening..." : "Start Voice Log", icon: "mic.fill") {
                    Task { await recordVoice() }
                }

                SecondaryButton(title: "Parse & Save", icon: "tray.and.arrow.down.fill") {
                    saveParsed()
                }
                .disabled(transcript.isEmpty)

                if let result = parseResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Matched: \(result.matchedLead?.name ?? "No client match")")
                            .font(.subheadline.bold())
                        Text("Activity: \(result.activityType.rawValue)")
                            .font(.caption)
                        if let days = result.followUpDays {
                            Text("Follow-up in \(days) day(s)").font(.caption).foregroundStyle(AppTheme.tealGreen)
                        }
                    }
                    .cardStyle()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Voice Log")
        .onAppear {
            if transcript.isEmpty, !initialTranscript.isEmpty {
                transcript = initialTranscript
            }
            if autoSave, !transcript.isEmpty {
                saveParsed()
            }
        }
    }

    private func recordVoice() async {
        isRecording = true
        defer { isRecording = false }
        if let text = await appState.voice.transcribeOnce() {
            transcript = text
            parseResult = appState.crmHub.parseVoiceLog(text, leads: appState.crm.leads)
        }
    }

    private func saveParsed() {
        let result = appState.crmHub.parseVoiceLog(transcript, leads: appState.crm.leads)
        parseResult = result
        guard let lead = result.matchedLead else { return }
        appState.crm.logContact(for: lead.id, type: result.activityType, summary: result.summary)
        if let days = result.followUpDays,
           let date = Calendar.current.date(byAdding: .day, value: days, to: .now) {
            appState.crm.scheduleFollowUp(for: lead.id, date: date)
        }
        Haptic.success()
    }
}

// MARK: - Commission & Quota

struct CommissionDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var targetText = ""

    private var userId: String { appState.auth.currentUser?.id ?? "" }
    private var revenue: Double { appState.commission.revenueThisMonth(orders: appState.audit.closedOrders, userId: userId) }
    private var commission: Double { appState.commission.commissionThisMonth(orders: appState.audit.closedOrders, userId: userId) }
    private var progress: Double { appState.commission.quotaProgress(orders: appState.audit.closedOrders, userId: userId) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                QuotaRingView(progress: progress, revenue: revenue, target: appState.commission.settings.monthlyRevenueTarget)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    CRMKPICard(title: "Revenue", value: formatCurrency(revenue), trend: nil, icon: "dollarsign.circle.fill", color: AppTheme.successGreen)
                    CRMKPICard(title: "Commission", value: formatCurrency(commission), trend: nil, icon: "percent", color: AppTheme.tealGreen)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Monthly Quota Target").font(.headline)
                    TextField("Target amount", text: $targetText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(AppTextFieldStyle())
                    PrimaryButton(title: "Save Quota", icon: "target") {
                        if let value = Double(targetText), value > 0 {
                            appState.commission.updateMonthlyTarget(value, for: userId)
                            appState.crm.defaultCommissionRate = appState.commission.settings.defaultCommissionRate
                        }
                    }
                }
                .cardStyle()

                SectionHeader(title: "Recent Closed Deals")
                ForEach(appState.audit.closedOrders.prefix(8)) { order in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(order.clientName).font(.subheadline.bold())
                            Text(order.closedAt.formatted(date: .abbreviated, time: .omitted)).font(.caption2).foregroundStyle(AppTheme.textMuted)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(formatCurrency(order.finalValue)).font(.subheadline.bold()).foregroundStyle(AppTheme.successGreen)
                            Text("Comm: \(formatCurrency(order.commissionAmount))").font(.caption2).foregroundStyle(AppTheme.tealGreen)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Commission")
        .onAppear {
            targetText = String(Int(appState.commission.settings.monthlyRevenueTarget))
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1000 { return String(format: "$%.0fK", value / 1000) }
        return String(format: "$%.0f", value)
    }
}

struct QuotaRingView: View {
    let progress: Double
    let revenue: Double
    let target: Double

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().stroke(AppTheme.electricBlueBright.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppTheme.successGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.successGreen)
                    Text("of quota").font(.caption2).foregroundStyle(AppTheme.textMuted)
                }
            }
            .frame(width: 120, height: 120)
            Text("\(formatShort(revenue)) / \(formatShort(target)) this month")
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func formatShort(_ value: Double) -> String {
        if value >= 1000 { return String(format: "$%.0fK", value / 1000) }
        return String(format: "$%.0f", value)
    }
}

// MARK: - Team Win Library

struct TeamWinLibraryView: View {
    @Environment(AppState.self) private var appState

    private var wins: [TeamWinHighlight] {
        CoachingIntelligenceService.shared.teamWinHighlights(
            from: appState.teamSales.feed(for: appState.auth.currentUser?.teamId ?? "solo")
        )
    }

    var body: some View {
        List {
            if wins.isEmpty {
                Text("Log wins in Team Sales Log to build your team's playbook library.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(wins) { win in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(win.repName).font(.caption.bold()).foregroundStyle(AppTheme.tealGreen)
                            Spacer()
                            Text("$\(Int(win.amount))").font(.headline.bold()).foregroundStyle(AppTheme.successGreen)
                        }
                        Text(win.clientLabel).font(.subheadline.bold())
                        Text(win.loggedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(AppTheme.textMuted)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Win Library")
    }
}

// MARK: - HubSpot-style CRM Hub

struct HubSpotCRMHubView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var portalId = ""

    var body: some View {
        List {
            Section("HubSpot-style CRM Hub") {
                NavigationLink { DuplicateMergeView() } label: {
                    Label("Duplicate Merge", systemImage: "person.2.badge.gearshape")
                }
                NavigationLink { EmailTemplatesView() } label: {
                    Label("Email Templates", systemImage: "envelope.badge.fill")
                }
                NavigationLink { CRMSequencesView() } label: {
                    Label("Email Sequences", systemImage: "arrow.triangle.2.circlepath")
                }
                NavigationLink { CRMSetupChecklistView() } label: {
                    Label("Setup Checklist", systemImage: "checklist")
                }
            }

            Section("HubSpot Sync") {
                Toggle("Enable local sync profile", isOn: Binding(
                    get: { appState.crmHub.hubSpotSettings.isEnabled },
                    set: {
                        if let userId = appState.auth.currentUser?.id {
                            appState.crmHub.setHubSpotEnabled($0, for: userId)
                        }
                    }
                ))
                TextField("Portal ID (optional)", text: $portalId)
                Button("Sync contacts & deals now") {
                    if let userId = appState.auth.currentUser?.id {
                        appState.crmHub.simulateHubSpotSync(crm: appState.crm, userId: userId)
                    }
                    Haptic.success()
                }
                if let synced = appState.crmHub.hubSpotSettings.lastSyncedAt {
                    Text("Last sync: \(synced.formatted(date: .abbreviated, time: .shortened)) · \(appState.crmHub.hubSpotSettings.contactsPushed) contacts")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("HubSpot CRM")
        .onAppear { portalId = appState.crmHub.hubSpotSettings.portalId }
    }
}

struct DuplicateMergeView: View {
    @Environment(AppState.self) private var appState
    @State private var mergedMessage: String?

    private var groups: [[Lead]] {
        appState.crmHub.findDuplicateGroups(in: appState.crm.leads)
    }

    var body: some View {
        List {
            if groups.isEmpty {
                Text("No duplicate groups detected.").font(.caption).foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(groups, id: \.first?.id) { group in
                    Section(group.first?.company.isEmpty == false ? group.first!.company : group.first!.name) {
                        ForEach(group) { lead in
                            Text("\(lead.name) · \(lead.phone.isEmpty ? lead.email : lead.phone)")
                                .font(.caption)
                        }
                        Button("Merge into first record") {
                            guard group.count > 1 else { return }
                            _ = appState.crmHub.mergeLeads(primaryId: group[0].id, secondaryId: group[1].id, crm: appState.crm)
                            mergedMessage = "Merged 2 records"
                            Haptic.success()
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Merge Duplicates")
        .alert("Merged", isPresented: .constant(mergedMessage != nil)) {
            Button("OK") { mergedMessage = nil }
        } message: { Text(mergedMessage ?? "") }
    }
}

struct EmailTemplatesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List(appState.crmHub.emailTemplates) { template in
            VStack(alignment: .leading, spacing: 6) {
                Text(template.name).font(.headline)
                Text(template.subject).font(.caption.bold()).foregroundStyle(AppTheme.tealGreen)
                Text(template.body).font(.caption).lineLimit(3)
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Email Templates")
    }
}

struct CRMSequencesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        List(appState.crmHub.sequences) { sequence in
            VStack(alignment: .leading, spacing: 8) {
                Text(sequence.name).font(.headline)
                Text("\(sequence.steps.count) steps").font(.caption).foregroundStyle(AppTheme.textMuted)
                Menu("Apply to client...") {
                    ForEach(appState.crm.leads.prefix(12)) { lead in
                        Button(lead.name) {
                            var updated = lead
                            appState.crmHub.applySequence(sequence, to: &updated, crm: appState.crm)
                            Haptic.success()
                        }
                    }
                }
                .font(.caption.bold())
            }
            .padding(.vertical, 4)
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("Sequences")
    }
}

struct CRMSetupChecklistView: View {
    @Environment(AppState.self) private var appState

    private var checklist: CRMSetupChecklist {
        appState.crmHub.setupChecklist(
            crm: appState.crm,
            calendarEnabled: appState.calendar.syncEnabled,
            aiConfigured: AppConfig.isAIConfigured
        )
    }

    var body: some View {
        List(checklist.items) { item in
            HStack {
                Image(systemName: item.icon).foregroundStyle(item.isComplete ? AppTheme.successGreen : AppTheme.textMuted)
                Text(item.title)
                Spacer()
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isComplete ? AppTheme.successGreen : AppTheme.textMuted)
            }
        }
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle("CRM Setup")
    }
}

struct LeadAttachmentsSection: View {
    @Binding var attachments: [LeadAttachment]
    @State private var newName = ""
    @State private var newKind: LeadAttachment.AttachmentKind = .proposal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Documents")
            HStack {
                TextField("Document name", text: $newName).textFieldStyle(AppTextFieldStyle())
                Picker("", selection: $newKind) {
                    ForEach(LeadAttachment.AttachmentKind.allCases, id: \.self) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .labelsHidden()
            }
            SecondaryButton(title: "Attach", icon: "paperclip") {
                guard !newName.isEmpty else { return }
                attachments.insert(LeadAttachment(fileName: newName, kind: newKind), at: 0)
                newName = ""
            }
            ForEach(attachments) { file in
                HStack {
                    Image(systemName: "doc.fill").foregroundStyle(AppTheme.electricBlueBright)
                    VStack(alignment: .leading) {
                        Text(file.fileName).font(.caption.bold())
                        Text(file.kind.rawValue).font(.caption2).foregroundStyle(AppTheme.textMuted)
                    }
                    Spacer()
                    Button { attachments.removeAll { $0.id == file.id } } label: {
                        Image(systemName: "trash").font(.caption)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct ManagerCoachingLoopView: View {
    @Environment(AppState.self) private var appState

    private var gap: SkillGapSnapshot {
        CRMEnhancements.skillGap(training: appState.training, crm: appState.crm)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CRMKPICard(title: "Training Score", value: "\(gap.overallTrainingScore)", trend: nil, icon: "mic.fill", color: AppTheme.electricBlueBright)
                CRMKPICard(title: "Win Rate", value: "\(Int(gap.winRate))%", trend: nil, icon: "trophy.fill", color: AppTheme.successGreen)
                Text("Weakest skill: \(gap.weakestSkill)").font(.subheadline.bold())
                PrimaryButton(title: "Assign Drill from Skill Gap", icon: "list.bullet.clipboard.fill") {
                    if let userId = appState.auth.currentUser?.id {
                        CoachingIntelligenceService.shared.assignDrillFromSkillGap(
                            weakestSkill: gap.weakestSkill,
                            teamGoals: appState.teamGoals,
                            userId: userId
                        )
                        Haptic.success()
                    }
                }
                NavigationLink { ManagerDrillsView() } label: {
                    Label("View assigned drills", systemImage: "chevron.right")
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Manager Coaching")
    }
}

struct PostCallDebriefSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let lead: Lead
    @State private var notes = ""
    @State private var debrief: PostVisitDebrief?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("What happened on the call?", text: $notes, axis: .vertical)
                        .lineLimit(4...8)
                        .textFieldStyle(AppTextFieldStyle())
                    PrimaryButton(title: isLoading ? "Analyzing..." : "Generate Debrief", icon: "sparkles") {
                        Task {
                            isLoading = true
                            appState.crm.logContact(for: lead.id, type: .call, summary: notes)
                            debrief = try? await DealCoachingService.shared.generatePostVisitDebrief(for: lead, visitNotes: notes)
                            isLoading = false
                        }
                    }
                    .disabled(notes.isEmpty || isLoading)
                    if let debrief { PostVisitDebriefCard(debrief: debrief) }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Post-Call Debrief")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
