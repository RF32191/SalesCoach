import SwiftUI

struct AITrainingRootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: TrainingTab = .roleplay

    enum TrainingTab: String, CaseIterable {
        case roleplay = "Roleplay"
        case chat = "AI Coach"
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
                    Text("Set RAILWAY_API_URL in scheme for live AI")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.warningOrange)
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
