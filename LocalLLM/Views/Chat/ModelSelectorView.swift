import SwiftUI

struct ModelSelectorView: View {
    let conversation: Conversation
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var modelManager = ModelManager.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        NavigationStack {
            List {
                if modelManager.downloadedModels.isEmpty {
                    ContentUnavailableView(
                        "No Models Downloaded",
                        systemImage: "arrow.down.circle",
                        description: Text("Go to the Models tab to download a model.")
                    )
                } else {
                    ForEach(modelManager.downloadedModels) { model in
                        Button {
                            conversation.modelId = model.id
                            modelManager.selectModel(model)
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(model.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(model.parameterCount) • \(model.quantization) • \(model.sizeFormatted)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if conversation.modelId == model.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(themeManager.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
