import SwiftUI

struct VoiceRoleplaySetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var preselectedScenario: TrainingScenario?
    @State private var selectedScenario: TrainingScenario = .coldCall
    @State private var selectedPersonality: CustomerPersonality = .interested
    @State private var startSession = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AppTheme.electricBlue)
                    Text("Voice Roleplay Setup")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("Choose a scenario and customer personality")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Scenario")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(TrainingScenario.allCases) { scenario in
                        SelectableRow(
                            title: scenario.rawValue,
                            subtitle: scenario.description,
                            icon: scenario.icon,
                            isSelected: selectedScenario == scenario
                        ) {
                            selectedScenario = scenario
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Customer Personality")
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(CustomerPersonality.allCases) { personality in
                        SelectableRow(
                            title: personality.rawValue,
                            subtitle: personality.description,
                            icon: personality.icon,
                            isSelected: selectedPersonality == personality
                        ) {
                            selectedPersonality = personality
                        }
                    }
                }

                if !appState.subscription.canStartRoleplay() {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.warningOrange)
                        Text("You've used all roleplays this month. Upgrade to Pro for more.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .cardStyle()
                }

                PrimaryButton(
                    title: "Start Roleplay",
                    icon: "mic.fill",
                    isDisabled: !appState.subscription.canStartRoleplay()
                ) {
                    appState.subscription.recordRoleplay()
                    startSession = true
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Setup")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            if let preselected = preselectedScenario {
                selectedScenario = preselected
            }
        }
        .navigationDestination(isPresented: $startSession) {
            VoiceRoleplayView(scenario: selectedScenario, personality: selectedPersonality)
        }
    }
}

struct SelectableRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? AppTheme.electricBlue : AppTheme.textMuted)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.electricBlue : AppTheme.textMuted)
            }
            .padding(12)
            .background(isSelected ? AppTheme.electricBlue.opacity(0.1) : AppTheme.navyCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.electricBlue : AppTheme.border, lineWidth: 1)
            )
        }
    }
}
