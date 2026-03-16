import SwiftUI
import SwiftData

struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    @Binding var selectedConversation: Conversation?
    @StateObject private var modelManager = ModelManager.shared

    var body: some View {
        List(selection: $selectedConversation) {
            ForEach(conversations) { conversation in
                NavigationLink(value: conversation) {
                    conversationRow(conversation)
                }
            }
            .onDelete(perform: deleteConversations)
        }
        .navigationTitle("Conversations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNewConversation) {
                    Image(systemName: "square.and.pencil")
                }
                .disabled(modelManager.downloadedModels.isEmpty)
            }
        }
        .overlay {
            if conversations.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Tap + to start a new chat")
                )
            }
        }
    }

    private func conversationRow(_ conversation: Conversation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)

            Text(conversation.preview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                if let model = ModelInfo.catalog.first(where: { $0.id == conversation.modelId }) {
                    Text(model.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.purple.opacity(0.2))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }

                Spacer()

                Text(conversation.updatedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func createNewConversation() {
        let modelId = modelManager.selectedModelId ?? modelManager.downloadedModels.first?.id ?? ""
        let conversation = Conversation(modelId: modelId)
        modelContext.insert(conversation)
        selectedConversation = conversation
    }

    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = conversations[index]
            if selectedConversation?.id == conversation.id {
                selectedConversation = nil
            }
            modelContext.delete(conversation)
        }
    }
}
