import SwiftUI

struct TrainingHubView: View {
    @Environment(AppState.self) private var appState
    var showNavigationChrome: Bool = true

    var body: some View {
        Group {
            if showNavigationChrome {
                NavigationStack { trainingContent }
            } else {
                trainingContent
            }
        }
    }

    private var trainingContent: some View {
        ScrollView {
                VStack(spacing: 20) {
                    NavigationLink {
                        VoiceRoleplaySetupView()
                    } label: {
                        FeatureCard(
                            title: "Voice AI Roleplay",
                            subtitle: "Speak with AI customers in real time",
                            icon: "mic.circle.fill",
                            accentColor: AppTheme.electricBlue
                        )
                    }
                    .buttonStyle(.plain)

                    SectionHeader(title: "Training Scenarios")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(TrainingScenario.allCases) { scenario in
                            NavigationLink {
                                VoiceRoleplaySetupView(preselectedScenario: scenario)
                            } label: {
                                ScenarioTile(scenario: scenario)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    SectionHeader(title: "Customer Personalities")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(CustomerPersonality.allCases) { personality in
                                PersonalityChip(personality: personality)
                            }
                        }
                    }

                    NavigationLink {
                        UltimateSalesHubView()
                    } label: {
                        FeatureCard(
                            title: "Ultimate Training Toolkit",
                            subtitle: "Certifications, battle mode, call analysis, and skill gaps",
                            icon: "star.circle.fill",
                            accentColor: AppTheme.warningOrange
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ConversationTrainingLogView()
                    } label: {
                        FeatureCard(
                            title: "Activity Log",
                            subtitle: "Saved roleplays with scores and chat history you can continue",
                            icon: "clock.arrow.circlepath",
                            accentColor: AppTheme.tealGreen
                        )
                    }
                    .buttonStyle(.plain)

                    let inProgress = appState.training.inProgressSessions(for: appState.auth.currentUser?.id ?? "")
                    if let session = inProgress.first {
                        NavigationLink {
                            VoiceRoleplayView(
                                scenario: session.scenario,
                                personality: session.personality,
                                resumeSession: session
                            )
                        } label: {
                            FeatureCard(
                                title: "Continue Roleplay",
                                subtitle: "\(session.scenario.rawValue) · \(session.transcript.count) turns so far",
                                icon: "play.circle.fill",
                                accentColor: AppTheme.electricBlueBright
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .appBackground()
            .navigationTitle("Train")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
    }
}

struct ScenarioTile: View {
    let scenario: TrainingScenario

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: scenario.icon)
                .font(.title2)
                .foregroundStyle(AppTheme.electricBlue)
            Text(scenario.rawValue)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

struct PersonalityChip: View {
    let personality: CustomerPersonality

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: personality.icon)
                    .foregroundStyle(AppTheme.electricBlue)
                Text(personality.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
            }
            Text(personality.description)
                .font(.caption2)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
        }
        .frame(width: 160)
        .padding(12)
        .background(AppTheme.navyCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
