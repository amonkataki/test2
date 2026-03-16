import SwiftUI
import SwiftData

struct ChatView: View {
    let conversation: Conversation
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var modelManager = ModelManager.shared
    @State private var showModelSelector = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            messagesScrollView

            // Input bar
            inputBar
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                modelSelectorButton
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        clearConversation()
                    } label: {
                        Label("Clear Chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showModelSelector) {
            ModelSelectorView(conversation: conversation)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error ?? "")
        }
    }

    private var modelSelectorButton: some View {
        Button(action: { showModelSelector = true }) {
            HStack(spacing: 4) {
                if let model = ModelInfo.catalog.first(where: { $0.id == conversation.modelId }) {
                    Text(model.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Select Model")
                        .font(.subheadline)
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)
        }
    }

    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(conversation.sortedMessages) { message in
                        MessageBubble(
                            message: message,
                            onRegenerate: message.role == .assistant ? {
                                Task { await viewModel.regenerateLastResponse(in: conversation) }
                            } : nil,
                            onDelete: {
                                viewModel.deleteMessage(message, from: conversation)
                            }
                        )
                        .id(message.id)
                    }

                    // Streaming indicator
                    if viewModel.isGenerating && !viewModel.streamedResponse.isEmpty {
                        MessageBubble(
                            message: ChatMessage(role: .assistant, content: viewModel.streamedResponse),
                            isStreaming: true
                        )
                        .id("streaming")
                    }
                }
                .padding()
            }
            .onChange(of: conversation.messages.count) {
                withAnimation {
                    if let lastId = conversation.sortedMessages.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.streamedResponse) {
                withAnimation {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask me anything...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...6)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }

                if viewModel.isGenerating {
                    Button(action: { viewModel.stopGenerating() }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? .gray
                                    : .purple
                            )
                    }
                    .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    private func sendMessage() {
        Task {
            await viewModel.sendMessage(in: conversation)
        }
    }

    private func clearConversation() {
        for message in conversation.messages {
            modelContext.delete(message)
        }
        conversation.messages.removeAll()
        conversation.title = "New Chat"
        try? modelContext.save()
    }
}
