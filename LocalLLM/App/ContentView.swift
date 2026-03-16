import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var modelManager = ModelManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedTab = 0
    @State private var selectedConversation: Conversation?
    @State private var columnVisibility = NavigationSplitViewVisibility.automatic

    var body: some View {
        TabView(selection: $selectedTab) {
            chatTab
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(0)

            ModelCatalogView()
                .tabItem {
                    Label("Models", systemImage: "arrow.down.circle.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(themeManager.accentColor)
        .preferredColorScheme(themeManager.colorScheme)
    }

    @ViewBuilder
    private var chatTab: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ConversationListView(selectedConversation: $selectedConversation)
        } detail: {
            if let conversation = selectedConversation {
                ChatView(conversation: conversation)
            } else {
                emptyStateView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(themeManager.accentColor.opacity(0.6))

            Text("Local LLM Chat")
                .font(.title)
                .fontWeight(.bold)

            if modelManager.downloadedModels.isEmpty {
                Text("Download a model to get started")
                    .foregroundStyle(.secondary)

                Button("Browse Models") {
                    selectedTab = 1
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.accentColor)
            } else {
                Text("Select a conversation or start a new one")
                    .foregroundStyle(.secondary)

                Button("New Chat") {
                    createNewConversation()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.accentColor)
            }
        }
        .padding()
    }

    private func createNewConversation() {
        guard let modelId = modelManager.selectedModelId ?? modelManager.downloadedModels.first?.id else {
            return
        }
        let conversation = Conversation(modelId: modelId)
        modelContext.insert(conversation)
        selectedConversation = conversation
    }
}
