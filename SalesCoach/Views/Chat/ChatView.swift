import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    var embedded: Bool = false
    var prefillMessage: String = ""
    var autoSend: Bool = false

    @State private var messageText = ""
    @State private var showHistory = false
    @State private var showLimitAlert = false
    @State private var didAutoSend = false

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
                Text("Team posts work offline. AI coaching is optional — enable Railway only if you want script help.")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            inputBar
        }
        .appBackground()
        .navigationTitle("Team Sales Log")
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
                ToolbarItem(placement: embedded ? .topBarTrailing : .platformTrailing) {
                    HStack(spacing: 16) {
                        if !embedded {
                            NavigationLink {
                                ConversationTrainingLogView()
                            } label: {
                                Image(systemName: "list.bullet.rectangle")
                            }
                            .accessibilityLabel("Activity Log")
                        }
                        Button {
                            appState.chat.startNewConversation(userId: appState.auth.currentUser?.id ?? "")
                            showHistory = false
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
            }
        }
        .alert("Usage Limit Reached", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've used your AI tokens or chat limit for this month. Upgrade your plan for more.")
        }
        .onAppear {
            appState.chat.ensureCurrentConversation(for: appState.auth.currentUser?.id ?? "")
            if messageText.isEmpty, !prefillMessage.isEmpty {
                messageText = prefillMessage
            }
            if autoSend, !didAutoSend, !prefillMessage.isEmpty {
                didAutoSend = true
                send(prefillMessage)
            }
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
                            Text("Posting to team...")
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
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.tealGreen)
            Text("Team Sales Log")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)
            Text("Share closed deals and updates with reps invited by your company host. Clients never need this app — no API key required for team posts.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                SuggestionChip(text: "Closed $8k with Acme Corp today") { send($0) }
                SuggestionChip(text: "Just sold $12k to TechFlow") { send($0) }
                SuggestionChip(text: "Big win — signed renewal with Northwind") { send($0) }
            }
        }
        .padding(.vertical, 32)
    }

    private var conversationHistory: some View {
        List {
            if let current = appState.chat.currentConversation, !current.messages.isEmpty {
                Section("Current") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(current.title).font(.headline)
                        Text("\(current.messages.count) messages")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .listRowBackground(AppTheme.navyCard)
            }

            Section("Saved Conversations") {
                ForEach(appState.chat.conversations) { conversation in
                    Button {
                        appState.chat.selectConversation(conversation)
                        showHistory = false
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(conversation.title)
                                .font(.headline)
                                .foregroundStyle(AppTheme.textPrimary)
                            if let last = conversation.messages.last {
                                Text(last.content)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .lineLimit(2)
                            }
                            Text("\(conversation.messages.count) messages · \(conversation.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textMuted)
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
        }
        .scrollContentBackground(.hidden)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Share a sale or team update...", text: $messageText, axis: .vertical)
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

        let needsAI = ChatService.isCoachingRequest(trimmed)
        if needsAI {
            guard appState.subscription.canSendChat() else {
                showLimitAlert = true
                return
            }
            guard appState.subscription.canUseAI(estimatedTokens: SubscriptionService.estimateTokens(input: trimmed)) else {
                showLimitAlert = true
                return
            }
            appState.subscription.recordChatMessage()
        }

        messageText = ""
        Task {
            await appState.chat.sendMessage(
                trimmed,
                userId: appState.auth.currentUser?.id ?? "",
                repName: appState.auth.currentUser?.fullName ?? "Rep",
                teamId: appState.auth.currentUser?.teamId ?? "solo",
                companyName: appState.auth.currentUser?.companyName,
                teamMembers: appState.team.members,
                crm: appState.crm,
                audit: appState.audit,
                teamSales: appState.teamSales,
                gamification: appState.gamification
            )
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(isUser ? .white : AppTheme.textPrimary)
                    .padding(12)
                    .background(isUser ? AppTheme.electricBlue : AppTheme.navyCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if let actions = message.loggedActions, !actions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(actions, id: \.self) { action in
                            Label(action, systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.successGreen)
                        }
                    }
                    .padding(10)
                    .background(AppTheme.successGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

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
