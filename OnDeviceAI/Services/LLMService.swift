import Foundation
import Combine

@MainActor
final class LLMService: ObservableObject {
    static let shared = LLMService()

    @Published var isGenerating = false
    @Published var currentModelId: String?

    private let engine = LLMEngine()
    private let modelManager = ModelManager.shared

    struct GenerationConfig {
        var maxTokens: Int
        var temperature: Float
        var topP: Float
        var systemPrompt: String
        var contextSize: Int

        init() {
            let defaults = UserDefaults.standard
            self.maxTokens = defaults.integer(forKey: "maxTokens").nonZero ?? 512
            self.temperature = defaults.float(forKey: "temperature").nonZero ?? 0.7
            self.topP = defaults.float(forKey: "topP").nonZero ?? 0.9
            self.systemPrompt = defaults.string(forKey: "systemPrompt") ?? "You are a helpful AI assistant."
            self.contextSize = defaults.integer(forKey: "contextSize").nonZero ?? 2048
        }
    }

    func loadModel(_ modelId: String) async throws {
        guard let path = modelManager.modelPath(forId: modelId) else {
            throw LLMError.modelFileNotFound("No downloaded file for model: \(modelId)")
        }

        if engine.isModelLoaded, engine.loadedModelPath == path {
            currentModelId = modelId
            return
        }

        let config = GenerationConfig()
        try await engine.loadModel(at: path, contextSize: config.contextSize)
        currentModelId = modelId
    }

    func generate(
        messages: [(role: MessageRole, content: String)],
        config: GenerationConfig = GenerationConfig(),
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard let modelId = currentModelId ?? modelManager.selectedModelId else {
            throw LLMError.modelNotLoaded
        }

        if !engine.isModelLoaded || currentModelId != modelId {
            try await loadModel(modelId)
        }

        isGenerating = true
        defer { isGenerating = false }

        let prompt = buildPrompt(messages: messages, config: config)

        return try await engine.generate(
            prompt: prompt,
            maxTokens: config.maxTokens,
            temperature: config.temperature,
            topP: config.topP,
            onToken: onToken
        )
    }

    func stopGeneration() {
        engine.shouldStop = true
        isGenerating = false
    }

    private func buildPrompt(messages: [(role: MessageRole, content: String)], config: GenerationConfig) -> String {
        var prompt = "<|im_start|>system\n\(config.systemPrompt)<|im_end|>\n"

        for message in messages {
            switch message.role {
            case .user:
                prompt += "<|im_start|>user\n\(message.content)<|im_end|>\n"
            case .assistant:
                prompt += "<|im_start|>assistant\n\(message.content)<|im_end|>\n"
            case .system:
                break
            }
        }

        prompt += "<|im_start|>assistant\n"
        return prompt
    }
}

// MARK: - Helpers

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

private extension Float {
    var nonZero: Float? { self == 0 ? nil : self }
}
