import Foundation
import Combine

@MainActor
final class ModelManager: ObservableObject {
    static let shared = ModelManager()

    @Published var downloadedModels: [ModelInfo] = []
    @Published var selectedModelId: String?

    private let fileManager = FileManager.default

    var modelsDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("models", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    init() {
        refreshDownloadedModels()
        // Restore last selected model
        if let savedId = UserDefaults.standard.string(forKey: "selectedModelId") {
            selectedModelId = savedId
        }
    }

    func refreshDownloadedModels() {
        let dir = modelsDirectory
        downloadedModels = ModelInfo.catalog.filter { model in
            let path = dir.appendingPathComponent(model.fileName).path
            return fileManager.fileExists(atPath: path)
        }

        // If selected model was deleted, clear selection
        if let selectedId = selectedModelId,
           !downloadedModels.contains(where: { $0.id == selectedId }) {
            selectedModelId = downloadedModels.first?.id
        }
    }

    func selectModel(_ model: ModelInfo) {
        selectedModelId = model.id
        UserDefaults.standard.set(model.id, forKey: "selectedModelId")
    }

    func modelPath(for model: ModelInfo) -> String {
        modelsDirectory.appendingPathComponent(model.fileName).path
    }

    func modelPath(forId modelId: String) -> String? {
        guard let model = ModelInfo.catalog.first(where: { $0.id == modelId }) else { return nil }
        let path = modelsDirectory.appendingPathComponent(model.fileName).path
        return fileManager.fileExists(atPath: path) ? path : nil
    }

    func deleteModel(_ model: ModelInfo) throws {
        let path = modelsDirectory.appendingPathComponent(model.fileName)
        try fileManager.removeItem(at: path)
        refreshDownloadedModels()
    }

    func downloadState(for model: ModelInfo) -> ModelDownloadState {
        if downloadedModels.contains(where: { $0.id == model.id }) {
            return .downloaded
        }
        if let task = DownloadManager.shared.activeDownloads[model.id] {
            switch task.state {
            case .downloading:
                return .downloading(progress: task.progress)
            case .completed:
                return .downloaded
            case .failed(let error):
                return .error(error)
            case .paused:
                return .downloading(progress: task.progress)
            }
        }
        return .notDownloaded
    }

    var selectedModel: ModelInfo? {
        guard let id = selectedModelId else { return downloadedModels.first }
        return downloadedModels.first(where: { $0.id == id }) ?? downloadedModels.first
    }

    func diskUsage() -> Int64 {
        let dir = modelsDirectory
        guard let files = try? fileManager.contentsOfDirectory(atPath: dir.path) else { return 0 }
        return files.reduce(Int64(0)) { total, file in
            let path = dir.appendingPathComponent(file).path
            let attrs = try? fileManager.attributesOfItem(atPath: path)
            return total + (attrs?[.size] as? Int64 ?? 0)
        }
    }

    var diskUsageFormatted: String {
        ByteCountFormatter.string(fromByteCount: diskUsage(), countStyle: .file)
    }
}
