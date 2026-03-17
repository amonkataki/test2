import Foundation
import Combine

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadTask] = [:]

    private var urlSession: URLSession!
    private var delegates: [String: DownloadDelegate] = [:]

    struct DownloadTask: Identifiable {
        let id: String
        let modelInfo: ModelInfo
        var progress: Double
        var bytesDownloaded: Int64
        var totalBytes: Int64
        var state: TaskState

        enum TaskState {
            case downloading
            case paused
            case completed
            case failed(String)
        }
    }

    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.ondeviceai.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func downloadModel(_ model: ModelInfo) {
        guard activeDownloads[model.id] == nil else { return }

        guard let url = URL(string: model.downloadURL) else { return }

        let task = urlSession.downloadTask(with: url)
        task.taskDescription = model.id

        activeDownloads[model.id] = DownloadTask(
            id: model.id,
            modelInfo: model,
            progress: 0,
            bytesDownloaded: 0,
            totalBytes: model.sizeBytes,
            state: .downloading
        )

        task.resume()
    }

    func cancelDownload(modelId: String) {
        urlSession.getAllTasks { tasks in
            for task in tasks where task.taskDescription == modelId {
                task.cancel()
            }
        }
        Task { @MainActor in
            activeDownloads.removeValue(forKey: modelId)
        }
    }

    private func modelsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("models", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let modelId = downloadTask.taskDescription else { return }

        // Find the model info
        guard let model = ModelInfo.catalog.first(where: { $0.id == modelId }) else { return }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelsDir = docs.appendingPathComponent("models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        let destination = modelsDir.appendingPathComponent(model.fileName)

        do {
            // Remove existing file if any
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)

            Task { @MainActor in
                self.activeDownloads[modelId]?.state = .completed
                self.activeDownloads[modelId]?.progress = 1.0
                // Notify ModelManager
                ModelManager.shared.refreshDownloadedModels()
            }
        } catch {
            Task { @MainActor in
                self.activeDownloads[modelId]?.state = .failed(error.localizedDescription)
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let modelId = downloadTask.taskDescription else { return }

        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0.0

        Task { @MainActor in
            self.activeDownloads[modelId]?.progress = progress
            self.activeDownloads[modelId]?.bytesDownloaded = totalBytesWritten
            if totalBytesExpectedToWrite > 0 {
                self.activeDownloads[modelId]?.totalBytes = totalBytesExpectedToWrite
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let modelId = task.taskDescription, let error = error else { return }

        if (error as NSError).code == NSURLErrorCancelled { return }

        Task { @MainActor in
            self.activeDownloads[modelId]?.state = .failed(error.localizedDescription)
        }
    }
}
