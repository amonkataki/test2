import Foundation
import Combine

@MainActor
final class ModelCatalogViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedFamily: ModelFamily?

    private let modelManager = ModelManager.shared
    private let downloadManager = DownloadManager.shared

    var filteredModels: [ModelInfo] {
        var models = ModelInfo.catalog

        if let family = selectedFamily {
            models = models.filter { $0.family == family }
        }

        if !searchText.isEmpty {
            models = models.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.family.rawValue.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        return models
    }

    var families: [ModelFamily] {
        ModelFamily.allCases
    }

    func downloadState(for model: ModelInfo) -> ModelDownloadState {
        modelManager.downloadState(for: model)
    }

    func downloadModel(_ model: ModelInfo) {
        downloadManager.downloadModel(model)
    }

    func cancelDownload(_ model: ModelInfo) {
        downloadManager.cancelDownload(modelId: model.id)
    }

    func deleteModel(_ model: ModelInfo) {
        try? modelManager.deleteModel(model)
    }

    func selectModel(_ model: ModelInfo) {
        modelManager.selectModel(model)
    }
}
