import Foundation

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

struct ChatConversation: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        title: String = "New Conversation",
        messages: [ChatMessage] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct ChatMessage: Codable, Identifiable, Equatable {
    var id: String
    var role: ChatRole
    var content: String
    var timestamp: Date
    var loggedActions: [String]?

    init(id: String = UUID().uuidString, role: ChatRole, content: String, timestamp: Date = .now, loggedActions: [String]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.loggedActions = loggedActions
    }
}
