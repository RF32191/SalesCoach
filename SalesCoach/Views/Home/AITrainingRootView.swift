import SwiftUI

struct AITrainingRootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    var initialTab: TrainingTab = .roleplay
    @State private var selectedTab: TrainingTab

    enum TrainingTab: String, CaseIterable {
        case roleplay = "Roleplay"
        case chat = "Team Sales Log"
    }

    init(initialTab: TrainingTab = .roleplay) {
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            trainingHeader

            Picker("Mode", selection: $selectedTab) {
                ForEach(TrainingTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            switch selectedTab {
            case .roleplay:
                TrainingHubView(showNavigationChrome: false)
            case .chat:
                ChatView(embedded: true)
            }
        }
        .appBackground()
        .navigationTitle("AI Training")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private var trainingHeader: some View {
        VStack(spacing: 12) {
            HStack {
                AIStatusBadge()
                Spacer()
                if !AppConfig.isAIConfigured {
                    Text("Team posts work offline. AI coaching is optional.")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            TokenMeterView(
                used: appState.subscription.usage.aiTokensUsedThisMonth,
                limit: appState.subscription.usage.tier.monthlyTokenLimit,
                compact: true
            )
        }
        .padding()
    }
}
