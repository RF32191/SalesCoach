import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    var embedded: Bool = false

    @State private var messageText = ""
    @State private var showHistory = false
    @State private var showLimitAlert = false

    var body: some View {
        Group {
            if embedded {
                chatContent
            } else {
                NavigationStack { chatContent }
            }
        }
    }

    private var chatContent: some View {
        VStack(spacing: 0) {
            if showHistory {
                conversationHistory
            } else {
                chatMessages
            }

            if let error = appState.chat.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.dangerRed)
                    .padding(.horizontal)
            }

            if !AppConfig.isAIConfigured {
                Text("Connect Railway AI in Xcode scheme env vars for live coaching.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.warningOrange)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            inputBar
        }
        .appBackground()
        .navigationTitle("AI Sales Coach")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if !embedded {
                ToolbarItem(placement: .platformLeading) {
                    Button {
                        showHistory.toggle()
                    } label: {
                        Image(systemName: showHistory ? "bubble.left.fill" : "clock.arrow.circlepath")
                    }
                }
            }
            ToolbarItem(placement: embedded ? .topBarTrailing : .platformTrailing) {
                Button {
                    appState.chat.startNewConversation(userId: appState.auth.currentUser?.id ?? "")
                    showHistory = false
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .alert("Usage Limit Reached", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've used your AI tokens or chat limit for this month. Upgrade your plan for more.")
        }
    }

    private var chatMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if appState.chat.currentConversation?.messages.isEmpty != false {
                        welcomeMessage
                    }

                    ForEach(appState.chat.currentConversation?.messages ?? []) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if appState.chat.isLoading {
                        HStack {
                            ProgressView()
                                .tint(AppTheme.electricBlue)
                            Text("Coach is thinking...")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: appState.chat.currentConversation?.messages.count) {
                if let last = appState.chat.currentConversation?.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.electricBlue)
            Text("Your AI Sales Coach")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Ask me to write scripts, handle objections, improve pitches, or plan your closing strategy.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                SuggestionChip(text: "Help me handle price objections") { send($0) }
                SuggestionChip(text: "Write a cold call opening") { send($0) }
                SuggestionChip(text: "How do I close a hesitant buyer?") { send($0) }
            }
        }
        .padding(.vertical, 32)
    }

    private var conversationHistory: some View {
        List {
            ForEach(appState.chat.conversations) { conversation in
                Button {
                    appState.chat.selectConversation(conversation)
                    showHistory = false
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conversation.title)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .listRowBackground(AppTheme.navyCard)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    appState.chat.deleteConversation(appState.chat.conversations[index])
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask your sales coach...", text: $messageText, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(AppTheme.navyCard)
                .foregroundStyle(AppTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.border, lineWidth: 1)
                )

            Button {
                send(messageText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(messageText.isEmpty ? AppTheme.textMuted : AppTheme.electricBlue)
            }
            .disabled(messageText.isEmpty || appState.chat.isLoading)
        }
        .padding()
        .background(AppTheme.navyElevated)
    }

    private func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard appState.subscription.canSendChat() else {
            showLimitAlert = true
            return
        }
        guard appState.subscription.canUseAI(estimatedTokens: SubscriptionService.estimateTokens(input: trimmed)) else {
            showLimitAlert = true
            return
        }

        messageText = ""
        appState.subscription.recordChatMessage()
        Task {
            await appState.chat.sendMessage(trimmed, userId: appState.auth.currentUser?.id ?? "")
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(isUser ? .white : AppTheme.textPrimary)
                .padding(12)
                .background(isUser ? AppTheme.electricBlue : AppTheme.navyCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

struct SuggestionChip: View {
    let text: String
    let action: (String) -> Void

    var body: some View {
        Button { action(text) } label: {
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.electricBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.electricBlue.opacity(0.12))
                .clipShape(Capsule())
        }
    }
}
