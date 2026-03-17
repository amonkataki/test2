import Foundation
import SwiftData
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var currentInput = ""
    @Published var isGenerating = false
    @Published var streamedResponse = ""
    @Published var error: String?

    private let llmService = LLMService.shared
    private let modelManager = ModelManager.shared
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func sendMessage(in conversation: Conversation) async {
        let userText = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userText.isEmpty else { return }
        guard !isGenerating else { return }

        currentInput = ""
        error = nil
        isGenerating = true
        streamedResponse = ""

        // Add user message
        let userMessage = ChatMessage(role: .user, content: userText)
        userMessage.conversation = conversation
        conversation.messages.append(userMessage)
        conversation.updatedAt = Date()

        // Auto-title on first message
        if conversation.messages.count == 1 {
            conversation.title = String(userText.prefix(50))
        }

        try? modelContext?.save()

        // Prepare messages for LLM
        let messages = conversation.sortedMessages.map { (role: $0.role, content: $0.content) }

        // Create assistant message placeholder
        let assistantMessage = ChatMessage(role: .assistant, content: "")
        assistantMessage.conversation = conversation
        conversation.messages.append(assistantMessage)

        do {
            // Ensure model is loaded
            if let selectedModel = modelManager.selectedModel {
                try await llmService.loadModel(selectedModel.id)
            }

            let response = try await llmService.generate(messages: messages) { [weak self] token in
                guard let self = self else { return }
                self.streamedResponse += token
                assistantMessage.content = self.streamedResponse
            }

            assistantMessage.content = response
            conversation.updatedAt = Date()
            try? modelContext?.save()
        } catch {
            self.error = error.localizedDescription
            // Remove empty assistant message on error
            if assistantMessage.content.isEmpty {
                conversation.messages.removeAll { $0.id == assistantMessage.id }
                modelContext?.delete(assistantMessage)
            }
        }

        isGenerating = false
        streamedResponse = ""
    }

    func stopGenerating() {
        llmService.stopGeneration()
        isGenerating = false
    }

    func deleteMessage(_ message: ChatMessage, from conversation: Conversation) {
        conversation.messages.removeAll { $0.id == message.id }
        modelContext?.delete(message)
        try? modelContext?.save()
    }

    func regenerateLastResponse(in conversation: Conversation) async {
        let sorted = conversation.sortedMessages
        guard let lastAssistant = sorted.last, lastAssistant.role == .assistant else { return }

        // Remove last assistant message
        deleteMessage(lastAssistant, from: conversation)

        // Get the last user message and re-send
        if let lastUser = conversation.sortedMessages.last, lastUser.role == .user {
            currentInput = lastUser.content
            deleteMessage(lastUser, from: conversation)
            await sendMessage(in: conversation)
        }
    }
}
