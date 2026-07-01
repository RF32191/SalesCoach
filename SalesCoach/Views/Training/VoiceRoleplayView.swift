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
    @State private var isAwaitingUser = false

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
                            TranscriptBubble(entry: entry, customerLabel: personality.rawValue)
                                .id(entry.id)
                        }

                        if appState.voice.isListening,
                           !appState.voice.transcribedText.isEmpty {
                            TranscriptBubble(
                                entry: RoleplayTranscriptEntry(speaker: "You", text: appState.voice.transcribedText),
                                customerLabel: personality.rawValue,
                                isLive: true
                            )
                            .id("live-user")
                        }

                        if appState.training.isProcessing {
                            HStack {
                                ProgressView().tint(AppTheme.electricBlue)
                                Text("\(personality.rawValue) is thinking...")
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
                .onChange(of: appState.voice.transcribedText) {
                    withAnimation { proxy.scrollTo("live-user", anchor: .bottom) }
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
        .onAppear {
            appState.voice.onUtteranceFinished = { text in
                Task { await processUserMessage(text) }
            }
            startSession()
        }
        .onDisappear {
            timer?.invalidate()
            appState.voice.onUtteranceFinished = nil
            appState.voice.cancelListening()
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
                    Text("Listening — pause when done, AI responds automatically")
                        .font(.caption)
                        .foregroundStyle(AppTheme.dangerRed)
                }
            } else if appState.voice.isSpeaking {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.successGreen).frame(width: 8, height: 8)
                    Text("\(personality.rawValue) is speaking...")
                        .font(.caption)
                        .foregroundStyle(AppTheme.successGreen)
                }
            } else if isAwaitingUser {
                HStack(spacing: 6) {
                    Circle().fill(AppTheme.electricBlueBright).frame(width: 8, height: 8)
                    Text("Your turn — tap mic or start speaking")
                        .font(.caption)
                        .foregroundStyle(AppTheme.electricBlueBright)
                }
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
                        Task { await appState.voice.speak(lastAIReply, force: true) }
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
                        .foregroundStyle(AppTheme.tealGreen)
                }

                Text(appState.voice.isListening ? "Pause to send · AI replies with voice + text" : "Tap mic to speak")
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
            await deliverCustomerOpening()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func deliverCustomerOpening() async {
        guard appState.subscription.canUseAI(estimatedTokens: 400) else {
            appState.training.errorMessage = "AI token limit reached for this month."
            return
        }

        if let turn = try? await OpenAIService.shared.roleplayTurn(
            scenario: scenario,
            personality: personality,
            transcript: []
        ) {
            await respondAsCustomer(turn.customerReply, applyResult: turn)
        }

        beginListeningForUser()
    }

    private func processUserMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            beginListeningForUser()
            return
        }
        guard !appState.training.isProcessing, !appState.voice.isSpeaking else { return }

        guard appState.subscription.canUseAI(estimatedTokens: 300) else {
            appState.training.errorMessage = "AI token limit reached for this month."
            return
        }

        isAwaitingUser = false
        appState.training.addUserMessage(trimmed)

        if let response = await appState.training.getAIResponse() {
            await respondAsCustomer(response)
        }

        beginListeningForUser()
    }

    private func respondAsCustomer(_ reply: String, applyResult: RoleplayTurnResult? = nil) async {
        let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let applyResult {
            appState.training.applyTurnResult(applyResult)
        }

        appState.training.addAIMessage(trimmed)
        lastAIReply = trimmed
        await appState.voice.speak(trimmed, force: true, personality: personality)
    }

    private func beginListeningForUser() {
        guard !isEnding, !appState.voice.isSpeaking, !appState.training.isProcessing else { return }
        isAwaitingUser = true
        do {
            try appState.voice.startListening()
        } catch {
            appState.training.errorMessage = error.localizedDescription
        }
    }

    private func toggleListening() {
        if appState.voice.isListening {
            appState.voice.stopListening()
        } else {
            isAwaitingUser = false
            do {
                try appState.voice.startListening()
            } catch {
                appState.training.errorMessage = error.localizedDescription
            }
        }
    }

    private func endSession() {
        appState.voice.cancelListening()
        appState.voice.stopSpeaking()
        timer?.invalidate()
        isEnding = true
        isAwaitingUser = false

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
    var customerLabel: String = "Customer"
    var isLive: Bool = false

    var isUser: Bool { entry.speaker == "You" }
    var speakerLabel: String { isUser ? "You" : customerLabel }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(speakerLabel)
                    .font(.caption2.bold())
                    .foregroundStyle(isUser ? AppTheme.electricBlue : AppTheme.successGreen)
                Text(entry.text)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(12)
                    .background(isUser ? AppTheme.electricBlue.opacity(isLive ? 0.12 : 0.2) : AppTheme.navyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isLive ? AppTheme.electricBlue.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
