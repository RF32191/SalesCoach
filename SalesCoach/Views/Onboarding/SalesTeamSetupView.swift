import SwiftUI

struct SalesTeamSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var isChangingCategory: Bool = false
    @State private var selectedCategory: SalesCategory = .b2bServices

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(SalesCategory.allCases) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                SalesCategorySelectionCard(
                                    category: category,
                                    isSelected: selectedCategory == category
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your workspace will focus on:")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                        Text(selectedCategory.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    PrimaryButton(title: "Continue with \(selectedCategory.rawValue)", icon: "checkmark.circle.fill") {
                        completeSetup()
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle(isChangingCategory ? "Change Sales Team" : "Your Sales Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isChangingCategory {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .onAppear {
                if let existing = appState.auth.currentUser?.salesCategory {
                    selectedCategory = existing
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedCategory.icon)
                .font(.system(size: 42))
                .foregroundStyle(selectedCategory.accentColor)
                .frame(width: 84, height: 84)
                .background(selectedCategory.accentColor.opacity(0.15))
                .clipShape(Circle())

            Text("What does your team sell?")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("We'll tailor your home screen, CRM, and company finder to your sales vertical.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    private func completeSetup() {
        appState.auth.updateSalesCategory(selectedCategory)
        if isChangingCategory {
            dismiss()
        } else {
            appState.loadUserData()
        }
    }
}

struct SalesCategorySelectionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let category: SalesCategory
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(category.accentColor)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(category.accentColor)
                }
            }

            Text(category.rawValue)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text(category.clientLabel)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? category.accentColor : AppTheme.borderColor(for: colorScheme), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct ContactIntelForm: View {
    @Binding var intel: ContactIntel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Details for Proximity Alerts")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("We'll remind you of these facts when you're nearby so you can personalize every visit.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)

            TextField("What they like (e.g. golf, local sports)", text: $intel.likes)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Interests & hobbies", text: $intel.interests)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Kids' names", text: $intel.kidsNames)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Family notes (spouse, pets, etc.)", text: $intel.familyNotes)
                .textFieldStyle(AppTextFieldStyle())
            TextField("Conversation starters", text: $intel.conversationStarters, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(AppTextFieldStyle())
        }
        .cardStyle()
    }
}

struct ProximityBriefingView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let lead: Lead

    private var category: SalesCategory? {
        SalesCategory.allCases.first { $0.rawValue == lead.leadSource }
            ?? appState.auth.currentUser?.salesCategory
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    contactFactsSection
                    arrivalChecklistSection
                    dealSection
                    actionSection
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Nearby Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Dismiss") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink {
                        LeadDetailView(lead: lead)
                    } label: {
                        Text("Open CRM")
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.fill.viewfinder")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.tealGreen)

            Text(category?.proximityAlertTitle ?? "You're near a pinned contact")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .multilineTextAlignment(.center)

            Text(lead.name)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            if !lead.company.isEmpty {
                Text(lead.company)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }

            if !lead.location.displayAddress.isEmpty {
                Label(lead.location.displayAddress, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var contactFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remember Before You Walk In")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            if lead.contactIntel.hasPersonalDetails {
                ForEach(lead.contactIntel.briefingFacts) { fact in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: fact.icon)
                            .foregroundStyle(category?.accentColor ?? AppTheme.electricBlueBright)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fact.label)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.textMuted)
                            Text(fact.value)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(AppTheme.elevatedBackground(for: colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Text("Add personal details in the CRM to get smarter proximity reminders.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(for: colorScheme))
            }

            if !lead.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textMuted)
                    Text(lead.notes)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                }
                .padding(12)
                .background(AppTheme.elevatedBackground(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var arrivalChecklistSection: some View {
        let checklist = DealCoachingService.shared.arrivalChecklist(for: lead, category: category)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Arrival Checklist")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))

            ForEach(Array(checklist.items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).")
                        .font(.caption.bold())
                        .foregroundStyle(category?.accentColor ?? AppTheme.tealGreen)
                        .frame(width: 18, alignment: .leading)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Talk Track")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textMuted)
                Text(checklist.talkTrack)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryText(for: colorScheme))
            }
            .padding(12)
            .background(AppTheme.elevatedBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text("Close Ask")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textMuted)
                Text(checklist.closeAsk)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.tealGreen)
            }
            .padding(12)
            .background(AppTheme.elevatedBackground(for: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var dealSection: some View {
        VStack(spacing: 10) {
            InfoRow(label: "Stage", value: lead.dealStage.rawValue)
            InfoRow(label: "Next step", value: lead.displayAIAction)
            if let followUp = lead.nextFollowUpDate {
                InfoRow(label: "Follow-up", value: followUp.formatted(date: .abbreviated, time: .omitted))
            }
        }
        .cardStyle()
    }

    private var actionSection: some View {
        VStack(spacing: 10) {
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

            NavigationLink {
                VoiceRoleplaySetupView(
                    preselectedScenario: DealCoachingService.shared.scenarioForLead(lead),
                    preselectedPersonality: DealCoachingService.shared.personalityForLead(lead),
                    practiceLead: lead
                )
            } label: {
                Label("Practice This Deal", systemImage: "mic.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(AppTheme.electricBlueBright)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)

            PrimaryButton(title: "Log Visit Now", icon: "figure.walk") {
                appState.crm.logContact(for: lead.id, type: .visit, summary: "Proximity visit logged near \(lead.company.isEmpty ? lead.name : lead.company)")
                appState.teamGoals.recordVisit()
                if let userId = appState.auth.currentUser?.id {
                    appState.teamGoals.save(for: userId)
                }
                dismiss()
            }
        }
    }
}
