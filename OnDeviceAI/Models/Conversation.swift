import Foundation
import SwiftData

@Model
final class Conversation {
    var id: UUID
    var title: String
    var modelId: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage]

    init(title: String = "New Chat", modelId: String) {
        self.id = UUID()
        self.title = title
        self.modelId = modelId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }

    var sortedMessages: [ChatMessage] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }

    var lastMessage: ChatMessage? {
        sortedMessages.last
    }

    var preview: String {
        lastMessage?.content ?? "No messages yet"
    }
}
