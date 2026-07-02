import SwiftUI
import UIKit

struct LeadDetailView: View {
    @Environment(AppState.self) private var appState
    @State var lead: Lead
    @State private var showFollowUp = false
    @State private var showScheduleFollowUp = false
    @State private var isUpdatingAction = false
    @State private var newActivitySummary = ""
    @State private var newActivityType: LeadActivityType = .note
    @State private var preCallBriefing: PreCallBriefing?
    @State private var isLoadingBriefing = false
    @State private var showDealOutcome = false
    @State private var showSnooze = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                dealHealthSection
                CRMQuickActionsBar(
                    lead: lead,
                    onCall: { dialLead() },
                    onEmail: { emailLead() },
                    onLogCall: { logQuickContact(type: .call, summary: "Outbound call with \(lead.name)") },
                    onLogEmail: { logQuickContact(type: .email, summary: "Sent email to \(lead.name)") },
                    onScheduleFollowUp: { showScheduleFollowUp = true },
                    onGenerateFollowUp: { showFollowUp = true }
                )
                dealInfoSection
                LeadTagsEditor(tags: $lead.tags)
                dealCoachingSection
                LeadTasksSection(leadId: lead.id)
                timelineSection
                ContactIntelForm(intel: $lead.contactIntel)
                LeadLocationSection(location: $lead.location)
                if lead.location.hasCoordinates,
                   let latitude = lead.location.latitude,
                   let longitude = lead.location.longitude {
                    AppleMapsNavigateButton(
                        title: "Navigate in Apple Maps",
                        name: lead.company.isEmpty ? lead.name : lead.company,
                        latitude: latitude,
                        longitude: longitude,
                        origin: appState.location.currentCoordinate
                    )
                }
                aiActionSection
                activitySection
                datesSection
                notesSection

                PrimaryButton(title: "Generate Follow-Up", icon: "sparkles") {
                    showFollowUp = true
                }

                SecondaryButton(title: "Refresh AI Recommendation", icon: "arrow.clockwise") {
                    refreshAIAction()
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle(lead.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    appState.crm.toggleFavorite(for: lead.id)
                    lead.isFavorite.toggle()
                    Haptic.selection()
                } label: {
                    Image(systemName: lead.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(AppTheme.warningOrange)
                }
            }
        }
        .sheet(isPresented: $showFollowUp) {
            FollowUpGeneratorView(lead: lead)
        }
        .confirmationDialog("Schedule Follow-Up", isPresented: $showScheduleFollowUp) {
            Button("Tomorrow") { scheduleFollowUp(days: 1) }
            Button("In 3 Days") { scheduleFollowUp(days: 3) }
            Button("Next Week") { scheduleFollowUp(days: 7) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Snooze Follow-Up", isPresented: $showSnooze) {
            Button("1 Day") { snooze(days: 1) }
            Button("3 Days") { snooze(days: 3) }
            Button("1 Week") { snooze(days: 7) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showDealOutcome) {
            DealOutcomeSheet(lead: lead) { finalValue in
                appState.crm.markWon(lead.id, finalValue: finalValue)
                if let updated = appState.crm.leads.first(where: { $0.id == lead.id }) { lead = updated }
                Haptic.success()
            } onLost: { reason in
                appState.crm.markLost(lead.id, reason: reason)
                if let updated = appState.crm.leads.first(where: { $0.id == lead.id }) { lead = updated }
            }
        }
        .onChange(of: lead) { _, newValue in
            appState.crm.updateLead(newValue)
            if newValue.location.pinReminderEnabled && newValue.location.hasCoordinates {
                appState.location.startGeofencing(for: appState.crm.leads.filter {
                    $0.location.pinReminderEnabled && $0.location.hasCoordinates
                })
            }
        }
    }

    private var dealHealthSection: some View {
        HStack(spacing: 16) {
            DealHealthRing(score: lead.dealHealthScore, size: 56)
            VStack(alignment: .leading, spacing: 6) {
                Text("Deal Health")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(lead.dealHealthLabel)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.textSecondary)
                Text("Based on probability, priority, and follow-up timing")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var dealCoachingSection: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                NavigationLink {
                    VoiceRoleplaySetupView(
                        preselectedScenario: DealCoachingService.shared.scenarioForLead(lead),
                        preselectedPersonality: DealCoachingService.shared.personalityForLead(lead),
                        practiceLead: lead
                    )
                } label: {
                    Label("Practice This Deal", systemImage: "mic.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.electricBlueBright.opacity(0.15))
                        .foregroundStyle(AppTheme.electricBlueBright)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    loadPreCallBriefing()
                } label: {
                    Label(isLoadingBriefing ? "Loading..." : "Pre-Call Brief", systemImage: "doc.text.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppTheme.tealGreen.opacity(0.15))
                        .foregroundStyle(AppTheme.tealGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            Button {
                appState.crm.applySmartFollowUp(to: lead.id)
                if let updated = appState.crm.leads.first(where: { $0.id == lead.id }) { lead = updated }
                Haptic.success()
            } label: {
                Label("Apply Smart Follow-Up Date", systemImage: "calendar.badge.clock")
                    .font(.caption.bold())
            }

            HStack(spacing: 10) {
                Button { showSnooze = true } label: {
                    Label("Snooze", systemImage: "moon.zzz.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.navyElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button { showDealOutcome = true } label: {
                    Label("Close Deal", systemImage: "flag.checkered")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppTheme.successGreen.opacity(0.15))
                        .foregroundStyle(AppTheme.successGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if lead.isStale {
                Label(lead.staleLabel, systemImage: "thermometer.snowflake")
                    .font(.caption)
                    .foregroundStyle(AppTheme.dangerRed)
            }

            if let preCallBriefing {
                PreCallBriefingView(lead: lead, briefing: preCallBriefing)
            }
        }
        .cardStyle()
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Deal Timeline").font(.headline).foregroundStyle(AppTheme.textPrimary)
            ForEach(lead.timelineEvents.prefix(8)) { event in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: event.type.icon).foregroundStyle(AppTheme.electricBlueBright).frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.summary).font(.caption).foregroundStyle(AppTheme.textPrimary)
                        Text(event.date.formatted(date: .abbreviated, time: .shortened)).font(.caption2).foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func loadPreCallBriefing() {
        isLoadingBriefing = true
        Task {
            preCallBriefing = try? await DealCoachingService.shared.generatePreCallBriefing(
                for: lead,
                category: appState.auth.currentUser?.salesCategory
            )
            isLoadingBriefing = false
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(lead.company)
                .font(.title3)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                StageBadge(stage: lead.dealStage)
                PriorityBadge(priority: lead.priority)
                Text(lead.leadSource)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.navyElevated)
                    .clipShape(Capsule())
            }
        }
    }

    private var dealInfoSection: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Deal Value", value: "$\(Int(lead.dealValue))")
            InfoRow(label: "Stage", value: lead.dealStage.rawValue)
            InfoRow(label: "Close Probability", value: "\(lead.probabilityOfClosing)%")

            Picker("Contact Role", selection: $lead.contactRole) {
                ForEach(ContactRole.allCases) { role in
                    Label(role.rawValue, systemImage: role.icon).tag(role)
                }
            }
            .pickerStyle(.menu)

            DatePicker(
                "Expected Close",
                selection: Binding(
                    get: { lead.expectedCloseDate ?? Calendar.current.date(byAdding: .month, value: 1, to: .now)! },
                    set: { lead.expectedCloseDate = $0 }
                ),
                displayedComponents: .date
            )
            .tint(AppTheme.electricBlue)

            TextField("Referral source", text: $lead.referralSource).textFieldStyle(AppTextFieldStyle())
            TextField("Competitor", text: $lead.competitorName).textFieldStyle(AppTextFieldStyle())
            TextField("Objection tags (comma separated)", text: Binding(
                get: { lead.objectionTags.joined(separator: ", ") },
                set: { lead.objectionTags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
            )).textFieldStyle(AppTextFieldStyle())

            Picker("Stage", selection: $lead.dealStage) {
                ForEach(DealStage.allCases) { stage in
                    Text(stage.rawValue).tag(stage)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.electricBlue)

            Picker("Priority", selection: $lead.priority) {
                ForEach(LeadPriority.allCases) { priority in
                    Text(priority.rawValue).tag(priority)
                }
            }
            .pickerStyle(.segmented)

            Slider(value: Binding(
                get: { Double(lead.probabilityOfClosing) },
                set: { lead.probabilityOfClosing = Int($0) }
            ), in: 0...100, step: 5) {
                Text("Probability")
            }
            .tint(AppTheme.electricBlue)
        }
        .cardStyle()
    }

    private var aiActionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.electricBlue)
                Text("AI Recommended Next Action")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }
            if isUpdatingAction {
                ProgressView().tint(AppTheme.electricBlue)
            } else {
                Text(lead.aiRecommendedAction)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .cardStyle()
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Activity Log")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Picker("Type", selection: $newActivityType) {
                ForEach(LeadActivityType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)

            TextField("Log activity...", text: $newActivitySummary, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(AppTextFieldStyle())

            SecondaryButton(title: "Add Activity", icon: "plus.circle") {
                guard !newActivitySummary.isEmpty else { return }
                let activity = LeadActivity(type: newActivityType, summary: newActivitySummary)
                lead.activities.insert(activity, at: 0)
                appState.crm.addActivity(to: lead.id, activity: activity)
                newActivitySummary = ""
            }

            ForEach(lead.activities.prefix(5)) { activity in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: activity.type.icon)
                        .foregroundStyle(AppTheme.electricBlueBright)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activity.summary)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(activity.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var datesSection: some View {
        VStack(spacing: 12) {
            InfoRow(label: "Phone", value: lead.phone.isEmpty ? "—" : lead.phone)
            InfoRow(label: "Email", value: lead.email.isEmpty ? "—" : lead.email)
            InfoRow(label: "Last Contacted", value: lead.lastContactedDate?.formatted(date: .abbreviated, time: .omitted) ?? "Never")
            InfoRow(label: "Next Follow-Up", value: lead.nextFollowUpDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
            if let expectedClose = lead.expectedCloseDate {
                InfoRow(label: "Expected Close", value: expectedClose.formatted(date: .abbreviated, time: .omitted))
            }
            if lead.dealStage == .lost, !lead.lostReason.isEmpty {
                InfoRow(label: "Lost Reason", value: lead.lostReason)
            }
        }
        .cardStyle()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            TextField("Add notes...", text: $lead.notes, axis: .vertical)
                .lineLimit(3...8)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .cardStyle()
    }

    private func refreshAIAction() {
        isUpdatingAction = true
        Task {
            if let action = try? await OpenAIService.shared.recommendNextAction(for: lead) {
                lead.aiRecommendedAction = action
                appState.crm.updateAIRecommendation(for: lead.id, action: action)
            }
            isUpdatingAction = false
        }
    }

    private func logQuickContact(type: LeadActivityType, summary: String) {
        appState.crm.logContact(for: lead.id, type: type, summary: summary)
        switch type {
        case .call:
            appState.teamGoals.recordCall()
            persistGoals()
        case .visit:
            appState.teamGoals.recordVisit()
            persistGoals()
        default: break
        }
        if let index = appState.crm.leads.firstIndex(where: { $0.id == lead.id }) {
            lead = appState.crm.leads[index]
        }
    }

    private func scheduleFollowUp(days: Int) {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        lead.nextFollowUpDate = date
        appState.crm.scheduleFollowUp(for: lead.id, date: date)
    }

    private func snooze(days: Int) {
        appState.crm.snoozeFollowUp(for: lead.id, days: days)
        if let updated = appState.crm.leads.first(where: { $0.id == lead.id }) { lead = updated }
    }

    private func dialLead() {
        let digits = lead.phone.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
        logQuickContact(type: .call, summary: "Called \(lead.name)")
    }

    private func emailLead() {
        guard !lead.email.isEmpty else { return }
        let subject = "Following up — \(lead.company.isEmpty ? lead.name : lead.company)"
        let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "mailto:\(lead.email)?subject=\(encoded)") else { return }
        UIApplication.shared.open(url)
        logQuickContact(type: .email, summary: "Emailed \(lead.name)")
    }

    private func persistGoals() {
        guard let userId = appState.auth.currentUser?.id else { return }
        appState.teamGoals.save(for: userId)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

struct AddLeadView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var company = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var dealValue = ""
    @State private var leadSource = "Manual"
    @State private var notes = ""
    @State private var contactIntel = ContactIntel()
    @State private var location = LeadLocation()
    @State private var showDuplicateAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Name", text: $name).textFieldStyle(AppTextFieldStyle())
                        TextField("Company", text: $company).textFieldStyle(AppTextFieldStyle())
                        TextField("Phone", text: $phone).textFieldStyle(AppTextFieldStyle()).keyboardType(.phonePad)
                        TextField("Email", text: $email).textFieldStyle(AppTextFieldStyle()).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                        TextField("Lead Source", text: $leadSource).textFieldStyle(AppTextFieldStyle())
                        TextField("Deal Value", text: $dealValue).textFieldStyle(AppTextFieldStyle()).keyboardType(.numberPad)
                        TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6).textFieldStyle(AppTextFieldStyle())
                    }
                    .cardStyle()

                    ContactIntelForm(intel: $contactIntel)
                    LeadLocationSection(location: $location)
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Add Lead")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveLead() }.disabled(name.isEmpty)
                }
            }
            .alert("Possible Duplicate", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("A lead with this name or company already exists in your CRM.")
            }
        }
    }

    private func saveLead() {
        let category = appState.auth.currentUser?.salesCategory
        let lead = Lead(
            ownerId: appState.auth.currentUser?.id ?? "",
            name: name,
            company: company,
            phone: phone,
            email: email,
            dealValue: Double(dealValue) ?? 0,
            notes: notes,
            leadSource: category?.rawValue ?? leadSource,
            contactIntel: contactIntel,
            location: location
        )
        if appState.crm.addLead(lead) {
            appState.teamGoals.recordNewLead()
            if let userId = appState.auth.currentUser?.id {
                appState.teamGoals.save(for: userId)
            }
            dismiss()
        } else {
            showDuplicateAlert = true
        }
    }
}
