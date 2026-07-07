import SwiftUI

enum PlatformRouter {
    @ViewBuilder
    static func view(for destination: PlatformDestination) -> some View {
        switch destination {
        case .crm: CRMView()
        case .pipeline: CRMView(initialViewMode: .pipeline)
        case .leadGen: LeadGenerationView()
        case .prospectResearch: ProspectResearchView()
        case .mapProspecting: CRMView(initialViewMode: .map)
        case .aiCoach: ChatView()
        case .roleplay: TrainingHubView()
        case .scriptMaker: ScriptMakerView()
        case .repDNA: RepDNAView()
        case .conversationIntel: ConversationIntelligenceView()
        case .emotionalIntel: EmotionalIntelligenceView()
        case .liveCopilot: LiveCallCopilotView()
        case .dealHealth: DealHealthCenterView()
        case .closingPredictor: ClosingPredictorView()
        case .forecasting: RevenueForecastingView()
        case .businessIntel: BusinessIntelligenceView()
        case .winLoss: WinLossAnalysisHubView()
        case .competitorIntel: CompetitorIntelligenceView()
        case .pricingAdvisor: PricingAdvisorView()
        case .enablement: UltimateSalesHubView()
        case .proposals: PlatformProposalView()
        case .contracts: ContractManagementView()
        case .customerSuccess: CustomerSuccessView()
        case .customerPortal: CustomerPortalView()
        case .marketing: MarketingAutomationView()
        case .emailAssistant: EmailAssistantView()
        case .communications: ActivityInboxView()
        case .workflows: WorkflowAutomationView()
        case .analytics: CRMDashboardView()
        case .aiManager: ManagerMorningBriefView()
        case .team: TeamDashboardView()
        case .leaderboard: LeaderboardView()
        case .office: OfficeTabView()
        case .billing: AutonomousBillingView()
        case .commission: CommissionCalculatorView()
        case .integrations: IntegrationsHubView()
        case .activityLog: ConversationTrainingLogView()
        case .crmImport: CRMImportView()
        case .businessCard: BusinessCardsHubView()
        case .digitalBusinessCard: DigitalBusinessCardEditorView()
        }
    }
}

struct PlatformRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""

    private var filteredCategories: [PlatformCategory] {
        guard !searchText.isEmpty else { return PlatformCategory.allCases }
        return PlatformCategory.allCases.filter { category in
            PlatformDestination.modules(in: category).contains { module in
                module.rawValue.localizedCaseInsensitiveContains(searchText) ||
                module.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                platformHeader
                searchBar

                ForEach(filteredCategories) { category in
                    categorySection(category)
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Platform")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                TutorialHelpButton(tutorialID: .platform)
            }
        }
    }

    private var platformHeader: some View {
        CRMGradientHeader(
            title: "Sales Coach AI",
            subtitle: "Every revenue tool — organized by job to be done",
            icon: "square.grid.3x3.fill",
            accent: AppTheme.electricBlueBright
        )
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.textMuted)
            TextField("Search modules...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func categorySection(_ category: PlatformCategory) -> some View {
        let modules = PlatformDestination.modules(in: category).filter { module in
            searchText.isEmpty ||
            module.rawValue.localizedCaseInsensitiveContains(searchText) ||
            module.subtitle.localizedCaseInsensitiveContains(searchText)
        }
        if !modules.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .foregroundStyle(AppTheme.tealGreen)
                    Text(category.rawValue)
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                    Spacer()
                    Text("\(modules.count)")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textMuted)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(modules) { module in
                        NavigationLink {
                            PlatformRouter.view(for: module)
                                .navigationTitle(module.rawValue)
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        TutorialHelpButton(tutorialID: module.tutorialID)
                                    }
                                }
                        } label: {
                            PlatformModuleCard(destination: module)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct PlatformModuleCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let destination: PlatformDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: destination.icon)
                .font(.title3)
                .foregroundStyle(AppTheme.electricBlueBright)
            Text(destination.rawValue)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.primaryText(for: colorScheme))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
            Text(destination.subtitle)
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .padding(12)
        .background(AppTheme.cardBackground(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(AppTheme.borderColor(for: colorScheme), lineWidth: 1)
        }
    }
}

struct CoachHubView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                CRMGradientHeader(
                    title: "AI Sales Coach",
                    subtitle: "Train, practice, and improve every conversation",
                    icon: "sparkles",
                    accent: AppTheme.tealGreen
                )

                ForEach([PlatformCategory.coach], id: \.self) { category in
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(PlatformDestination.modules(in: category)) { module in
                            NavigationLink {
                                PlatformRouter.view(for: module)
                                    .navigationTitle(module.rawValue)
                                    .navigationBarTitleDisplayMode(.inline)
                            } label: {
                                PlatformModuleCard(destination: module)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                NavigationLink {
                    StandoutFeaturesHubView()
                } label: {
                    FeatureCard(
                        title: "Coaching Toolkit",
                        subtitle: "Smart route, walk-in mode, deal replay, and more",
                        icon: "star.fill",
                        accentColor: AppTheme.warningOrange
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AITrainingRootView()
                } label: {
                    FeatureCard(
                        title: "Training Studio",
                        subtitle: "Roleplay + team sales log in one workspace",
                        icon: "mic.fill",
                        accentColor: AppTheme.electricBlueBright
                    )
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Coach")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                TutorialHelpButton(tutorialID: .coach)
            }
        }
    }
}
