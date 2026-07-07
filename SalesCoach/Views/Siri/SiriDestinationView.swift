import SwiftUI

struct SiriDestinationView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let request: SiriNavigationRequest
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            destinationContent
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            onDismiss()
                            dismiss()
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var destinationContent: some View {
        switch request.destination {
        case .practiceScenario(let scenario, let personality):
            VoiceRoleplayView(scenario: scenario, personality: personality)
        case .aiTraining(let tab):
            AITrainingRootView(initialTab: tab == .roleplay ? .roleplay : .chat)
        case .teamSalesLog(let prefill, let autoSend):
            ChatView(prefillMessage: prefill ?? "", autoSend: autoSend)
        case .voiceLog(let prefill, let autoSave):
            VoiceLogView(initialTranscript: prefill ?? "", autoSave: autoSave)
        }
    }
}
