import SwiftUI

struct ConversationTrainingLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var filter: LogFilter = .all

    enum LogFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case training = "Training"
        case chat = "Conversations"

        var id: String { rawValue }
    }

    private var userId: String { appState.auth.currentUser?.id ?? "" }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                CRMGradientHeader(
                    title: "Activity Log",
                    subtitle: "Saved roleplay sessions with scores, plus team chat history you can continue anytime.",
                    icon: "clock.arrow.circlepath",
                    accent: AppTheme.electricBlueBright
                )

                Picker("Filter", selection: $filter) {
                    ForEach(LogFilter.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                if filter == .all || filter == .training {
                    trainingSection
                }

                if filter == .all || filter == .chat {
                    chatSection
                }
            }
            .padding()
        }
        .appBackground()
        .navigationTitle("Activity Log")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }

    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Training Sessions")

            let inProgress = appState.training.inProgressSessions(for: userId)
            if !inProgress.isEmpty {
                ForEach(inProgress) { session in
                    NavigationLink {
                        VoiceRoleplayView(
                            scenario: session.scenario,
                            personality: session.personality,
                            resumeSession: session
                        )
                    } label: {
                        TrainingLogRow(session: session, showContinue: true)
                    }
                    .buttonStyle(.plain)
                }
            }

            let completed = appState.training.completedSessions(for: userId)
            if completed.isEmpty && inProgress.isEmpty {
                Text("No training sessions saved yet.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(completed) { session in
                    NavigationLink {
                        TrainingSessionDetailView(session: session)
                    } label: {
                        TrainingLogRow(session: session, showContinue: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var chatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Team Conversations")

            if appState.chat.conversations.isEmpty {
                Text("No saved conversations yet.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textMuted)
            } else {
                ForEach(appState.chat.conversations) { conversation in
                    NavigationLink {
                        ChatConversationDetailView(conversation: conversation)
                    } label: {
                        ChatLogRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct TrainingLogRow: View {
    let session: TrainingSession
    var showContinue: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.scenario.rawValue)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                Text(session.personality.rawValue)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                HStack(spacing: 8) {
                    Label("\(session.transcript.count) turns", systemImage: "text.bubble")
                    if let date = session.completedAt ?? session.startedAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .font(.caption2)
                .foregroundStyle(AppTheme.textMuted)
            }

            Spacer()

            if showContinue {
                Text("Continue")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.tealGreen)
                    .clipShape(Capsule())
            } else if let score = session.scoreReport?.overallScore {
                Text("\(score)")
                    .font(.title3.bold())
                    .foregroundStyle(scoreColor(score))
            } else {
                Text("—")
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .cardStyle()
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 80 { return AppTheme.successGreen }
        if score >= 60 { return AppTheme.electricBlue }
        return AppTheme.warningOrange
    }
}

struct ChatLogRow: View {
    let conversation: ChatConversation

    private var preview: String {
        conversation.messages.last?.content ?? "Empty conversation"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                Text("\(conversation.messages.count) messages · \(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textMuted)
            }
            Spacer()
            Image(systemName: "arrow.turn.up.left")
                .foregroundStyle(AppTheme.electricBlueBright)
        }
        .cardStyle()
    }
}

struct TrainingSessionDetailView: View {
    @Environment(AppState.self) private var appState
    let session: TrainingSession

    var body: some View {
        Group {
            if let report = session.scoreReport {
                ScoringReportView(report: report, session: session)
            } else {
                SessionTranscriptView(session: session)
            }
        }
        .navigationTitle(session.scenario.rawValue)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct SessionTranscriptView: View {
    @Environment(AppState.self) private var appState
    let session: TrainingSession

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(session.personality.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    if session.isInProgress {
                        Label("In progress — pick up where you left off", systemImage: "play.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.tealGreen)
                    } else {
                        Text("Session ended without a score.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }

                if session.isInProgress {
                    NavigationLink {
                        VoiceRoleplayView(
                            scenario: session.scenario,
                            personality: session.personality,
                            resumeSession: session
                        )
                    } label: {
                        Label("Continue Roleplay", systemImage: "mic.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.electricBlueBright)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                ForEach(session.transcript) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.speaker)
                                .font(.caption.bold())
                                .foregroundStyle(entry.speaker == "You" ? AppTheme.electricBlueBright : AppTheme.tealGreen)
                            Spacer()
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textMuted)
                        }
                        Text(entry.text)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(entry.speaker == "You" ? AppTheme.electricBlueBright.opacity(0.1) : AppTheme.navyElevated.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .appBackground()
    }
}

struct ChatConversationDetailView: View {
    @Environment(AppState.self) private var appState
    let conversation: ChatConversation

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conversation.messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
            }

            NavigationLink {
                ContinueChatView(conversation: conversation)
            } label: {
                Label("Continue Conversation", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.tealGreen)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding()
            }
            .buttonStyle(.plain)
        }
        .appBackground()
        .navigationTitle(conversation.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct ContinueChatView: View {
    @Environment(AppState.self) private var appState
    let conversation: ChatConversation

    var body: some View {
        ChatView(embedded: true)
            .onAppear {
                appState.chat.selectConversation(conversation)
            }
    }
}
