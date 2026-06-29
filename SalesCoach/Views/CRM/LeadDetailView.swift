import SwiftUI

struct LeadDetailView: View {
    @Environment(AppState.self) private var appState
    @State var lead: Lead
    @State private var showFollowUp = false
    @State private var isUpdatingAction = false
    @State private var newActivitySummary = ""
    @State private var newActivityType: LeadActivityType = .note

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection
                dealInfoSection
                LeadLocationSection(location: $lead.location)
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
        .sheet(isPresented: $showFollowUp) {
            FollowUpGeneratorView(lead: lead)
        }
        .onChange(of: lead) { _, newValue in
            appState.crm.updateLead(newValue)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(lead.company)
                .font(.title3)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                StageBadge(stage: lead.dealStage)
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

            Picker("Stage", selection: $lead.dealStage) {
                ForEach(DealStage.allCases) { stage in
                    Text(stage.rawValue).tag(stage)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.electricBlue)

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
    @State private var location = LeadLocation()

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
        }
    }

    private func saveLead() {
        let lead = Lead(
            ownerId: appState.auth.currentUser?.id ?? "",
            name: name,
            company: company,
            phone: phone,
            email: email,
            dealValue: Double(dealValue) ?? 0,
            notes: notes,
            leadSource: leadSource,
            location: location
        )
        appState.crm.addLead(lead)
        dismiss()
    }
}
