import SwiftUI

struct ProximityBriefingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    let lead: Lead

    @State private var briefing: PreCallBriefing?
    @State private var isLoading = false
    @State private var visitNotes = ""
    @State private var debrief: PostVisitDebrief?
    @State private var showDebrief = false

    private var checklist: ArrivalChecklist {
        DealCoachingService.shared.arrivalChecklist(for: lead, category: appState.auth.currentUser?.salesCategory)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CRMGradientHeader(
                        title: appState.auth.currentUser?.salesCategory?.proximityAlertTitle ?? "You're near a prospect",
                        subtitle: lead.company.isEmpty ? lead.name : "\(lead.name) · \(lead.company)",
                        icon: "location.fill",
                        accent: AppTheme.tealGreen
                    )

                    LeadContactLinkRow(
                        lead: lead,
                        onCall: { logAndCall() },
                        onEmail: { logAndEmail() },
                        onText: { logAndText() },
                        compact: true
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Arrival Checklist")
                        ForEach(checklist.items, id: \.self) { item in
                            Label(item, systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        }
                        Text("Close ask: \(checklist.closeAsk)")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.tealGreen)
                    }
                    .cardStyle()

                    if let briefing {
                        PreCallBriefingView(lead: lead, briefing: briefing)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "15-Second Objection Drill")
                        Text(lead.objectionTags.first ?? "Your price is too high")
                            .font(.headline)
                            .foregroundStyle(AppTheme.warningOrange)
                        NavigationLink {
                            VoiceRoleplaySetupView(
                                preselectedScenario: .objectionHandling,
                                preselectedPersonality: .skeptical,
                                practiceLead: lead
                            )
                        } label: {
                            Label("Practice this objection now", systemImage: "mic.fill")
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .foregroundStyle(AppTheme.electricBlueBright)
                                .background(AppTheme.electricBlueBright.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Log Visit Before You Leave")
                        TextField("What happened on-site?", text: $visitNotes, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(AppTextFieldStyle())
                        PrimaryButton(title: showDebrief ? "Updating..." : "Generate Visit Debrief", icon: "sparkles") {
                            Task { await runDebrief() }
                        }
                        .disabled(visitNotes.isEmpty || showDebrief)
                        if let debrief {
                            PostVisitDebriefCard(debrief: debrief)
                        }
                    }
                    .cardStyle()

                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        Label("Open Full Contact Record", systemImage: "person.crop.rectangle")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white)
                            .background(AppTheme.electricBlueBright)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Proximity Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await loadBriefing() }
        }
    }

    private func loadBriefing() async {
        isLoading = true
        briefing = try? await DealCoachingService.shared.generatePreCallBriefing(
            for: lead,
            category: appState.auth.currentUser?.salesCategory
        )
        isLoading = false
    }

    private func runDebrief() async {
        showDebrief = true
        appState.crm.logContact(for: lead.id, type: .visit, summary: visitNotes)
        debrief = try? await DealCoachingService.shared.generatePostVisitDebrief(for: lead, visitNotes: visitNotes)
        showDebrief = false
    }

    private func logAndCall() {
        LeadCommunicationService.call(lead: lead) {
            appState.crm.logContact(for: lead.id, type: .call, summary: "Proximity call to \(lead.name)")
        }
    }

    private func logAndEmail() {
        LeadCommunicationService.email(lead: lead) {
            appState.crm.logContact(for: lead.id, type: .email, summary: "Proximity email to \(lead.name)")
        }
    }

    private func logAndText() {
        LeadCommunicationService.text(lead: lead) {
            appState.crm.logContact(for: lead.id, type: .note, summary: "Texted \(lead.name) near location")
        }
    }
}

struct PostVisitDebriefCard: View {
    let debrief: PostVisitDebrief

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            bulletBlock("What went well", debrief.whatWentWell, AppTheme.successGreen)
            bulletBlock("Improve", debrief.improvements, AppTheme.warningOrange)
            Text("Next: \(debrief.nextStep)").font(.caption).foregroundStyle(AppTheme.textPrimary)
            Text(debrief.practicePrompt).font(.caption2).foregroundStyle(AppTheme.tealGreen)
        }
    }

    private func bulletBlock(_ title: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption.bold()).foregroundStyle(color)
            ForEach(items, id: \.self) { Label($0, systemImage: "circle.fill").font(.caption2) }
        }
    }
}
