import AppIntents

struct SalesCoachShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartPracticeScenarioIntent(),
            phrases: [
                "Practice \(\.$scenario) in \(.applicationName)",
                "Start \(\.$scenario) in \(.applicationName)",
                "Run \(\.$scenario) roleplay in \(.applicationName)"
            ],
            shortTitle: "Practice Scenario",
            systemImageName: "mic.fill"
        )

        AppShortcut(
            intent: StartObjectionPracticeIntent(),
            phrases: [
                "Practice objections in \(.applicationName)",
                "Handle objections in \(.applicationName)",
                "Start objection training in \(.applicationName)"
            ],
            shortTitle: "Objection Practice",
            systemImageName: "exclamationmark.bubble.fill"
        )

        AppShortcut(
            intent: OpenTeamSalesLogIntent(),
            phrases: [
                "Open team sales log in \(.applicationName)",
                "Log a team sale in \(.applicationName)",
                "Share a sale with my team in \(.applicationName)"
            ],
            shortTitle: "Team Sales Log",
            systemImageName: "person.3.fill"
        )

        AppShortcut(
            intent: LogTeamSaleIntent(),
            phrases: [
                "Log a team sale in \(.applicationName)",
                "Record a sale in \(.applicationName)"
            ],
            shortTitle: "Log Sale",
            systemImageName: "cart.fill"
        )

        AppShortcut(
            intent: OpenAITrainingIntent(),
            phrases: [
                "Open AI training in \(.applicationName)",
                "Open \(\.$tab) in \(.applicationName)",
                "Start sales training in \(.applicationName)"
            ],
            shortTitle: "AI Training",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: LogVoiceNoteIntent(),
            phrases: [
                "Log a CRM note in \(.applicationName)",
                "Log sales activity in \(.applicationName)",
                "Voice log a client in \(.applicationName)"
            ],
            shortTitle: "Voice CRM Log",
            systemImageName: "waveform.circle.fill"
        )
    }
}
