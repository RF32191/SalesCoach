import SwiftUI

struct VoiceRoleplayView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let scenario: TrainingScenario
    let personality: CustomerPersonality

    @State private var sessionStarted = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?
    @State private var scoreReport: TrainingScoreReport?
    @State private var isEnding = false
    @State private var showReport = false
    @State private var showVoiceSettings = false
    @State private var lastAIReply = ""

    var body: some View {
        VStack(spacing: 0) {
            sessionHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let session = appState.training.activeSession {
                            ClosingMeterView(progress: session.closingProgress)
                                .padding(.bottom, 4)

                            if let suggestion = session.currentSuggestion {
                                CoachSuggestionCard(suggestion: suggestion)
                            }
                        }

                        ForEach(appState.training.activeSession?.transcript ?? []) { entry in
                            TranscriptBubble(entry: entry)
                                .id(entry.id)
                        }

                        if appState.training.isProcessing {
                            HStack {
                                ProgressView().tint(AppTheme.electricBlue)
                                Text("Customer is responding...")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: appState.training.activeSession?.transcript.count) {
                    if let last = appState.training.activeSession?.transcript.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            voiceControls
        }
        .appBackground()
        .navigationTitle(scenario.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(sessionStarted)
        .toolbar {
            ToolbarItem(placement: .platformLeading) {
                Button {
                    showVoiceSettings = true
                } label: {
                    Image(systemName: "globe")
                }
            }
            if sessionStarted {
                ToolbarItem(placement: .platformTrailing) {
                    Button("End") { endSession() }
                        .foregroundStyle(AppTheme.dangerRed)
                }
            }
        }
        .sheet(isPresented: $showVoiceSettings) {
            VoiceSettingsSheet(voice: appState.voice)
        }
        .onAppear { startSession() }
        .onDisappear {
            timer?.invalidate()
            appState.voice.stopListening()
            appState.voice.stopSpeaking()
        }
        .navigationDestination(isPresented: $showReport) {
            if let report = scoreReport, let session = appState.training.lastCompletedSession {
                ScoringReportView(report: report, session: session)
            }
        }
    }

    private var sessionHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Label(personality.rawValue, systemImage: personality.icon)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.electricBlue)
                Spacer()
                Text(formatTime(elapsedSeconds))
                    .font(.caption.monospaced())
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if appState.voice.isListening {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.dangerRed).frame(width: 8, height: 8)
                    Text("Listening to you...")
                        .font(.caption)
                        .foregroundStyle(AppTheme.dangerRed)
                }
            } else if appState.voice.isSpeaking {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.successGreen).frame(width: 8, height: 8)
                    Text("AI customer speaking...")
                        .font(.caption)
                        .foregroundStyle(AppTheme.successGreen)
                }
            }

            if !appState.voice.transcribedText.isEmpty && appState.voice.isListening {
                Text(appState.voice.transcribedText)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(AppTheme.navyElevated)
    }

    private var voiceControls: some View {
        VStack(spacing: 12) {
            if isEnding {
                ProgressView("Scoring your session...")
                    .tint(AppTheme.electricBlue)
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                HStack(spacing: 20) {
                    Button {
                        Task { await appState.voice.speak(lastAIReply) }
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(lastAIReply.isEmpty ? AppTheme.textMuted : AppTheme.electricBlueBright)
                    }
                    .disabled(lastAIReply.isEmpty || appState.voice.isSpeaking)

                    Button { toggleListening() } label: {
                        ZStack {
                            Circle()
                                .fill(appState.voice.isListening ? AppTheme.dangerRed : AppTheme.electricBlue)
                                .frame(width: 72, height: 72)
                            Image(systemName: appState.voice.isListening ? "stop.fill" : "mic.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(appState.voice.isSpeaking || appState.training.isProcessing)

                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundStyle(appState.voice.settings.autoSpeakResponses ? AppTheme.tealGreen : AppTheme.textMuted)
                }

                Text(appState.voice.isListening ? "Tap to send" : "Tap to speak — AI responds aloud")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.navyElevated)
    }

    private func startSession() {
        guard let userId = appState.auth.currentUser?.id else { return }
        _ = appState.training.startSession(userId: userId, scenario: scenario, personality: personality)
        sessionStarted = true
        appState.training.setInitialSuggestion("Open strong: state who you are, why you're calling, and ask one discovery question.")

        Task {
            await appState.voice.requestPermissions()
            if let turn = try? await OpenAIService.shared.roleplayTurn(
                scenario: scenario,
                personality: personality,
                transcript: []
            ) {
                appState.training.applyTurnResult(turn)
                appState.training.addAIMessage(turn.customerReply)
                lastAIReply = turn.customerReply
                await appState.voice.speak(turn.customerReply)
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func toggleListening() {
        if appState.voice.isListening {
            let text = appState.voice.transcribedText
            appState.voice.stopListening()
            guard !text.isEmpty else { return }
            appState.training.addUserMessage(text)
            Task {
                if let response = await appState.training.getAIResponse() {
                    appState.training.addAIMessage(response)
                    lastAIReply = response
                    await appState.voice.speak(response)
                }
            }
        } else {
            do {
                try appState.voice.startListening()
            } catch {
                appState.training.errorMessage = error.localizedDescription
            }
        }
    }

    private func endSession() {
        appState.voice.stopListening()
        appState.voice.stopSpeaking()
        timer?.invalidate()
        isEnding = true

        Task {
            scoreReport = await appState.training.completeSession(durationSeconds: elapsedSeconds)
            isEnding = false
            showReport = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct TranscriptBubble: View {
    let entry: RoleplayTranscriptEntry
    var isUser: Bool { entry.speaker == "You" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(entry.speaker)
                    .font(.caption2.bold())
                    .foregroundStyle(isUser ? AppTheme.electricBlue : AppTheme.successGreen)
                Text(entry.text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background(isUser ? AppTheme.electricBlue.opacity(0.2) : AppTheme.navyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
