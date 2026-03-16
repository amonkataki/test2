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
        var maxTokens: Int = 512
        var temperature: Float = 0.7
        var topP: Float = 0.9
        var systemPrompt: String = "You are a helpful AI assistant."
    }

    func loadModel(_ modelId: String) async throws {
        guard let path = modelManager.modelPath(forId: modelId) else {
            throw LLMError.modelFileNotFound(modelId)
        }

        // Don't reload if already loaded
        if engine.isModelLoaded, engine.loadedModelPath == path {
            currentModelId = modelId
            return
        }

        try await engine.loadModel(at: path)
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

        // Ensure model is loaded
        if !engine.isModelLoaded || currentModelId != modelId {
            try await loadModel(modelId)
        }

        isGenerating = true
        defer { isGenerating = false }

        // Build the prompt from messages using chat template
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
        isGenerating = false
        // In real implementation: set a flag that the engine checks during generation
    }

    private func buildPrompt(messages: [(role: MessageRole, content: String)], config: GenerationConfig) -> String {
        // Build a ChatML-style prompt (works with most GGUF models)
        var prompt = "<|im_start|>system\n\(config.systemPrompt)<|im_end|>\n"

        for message in messages {
            switch message.role {
            case .user:
                prompt += "<|im_start|>user\n\(message.content)<|im_end|>\n"
            case .assistant:
                prompt += "<|im_start|>assistant\n\(message.content)<|im_end|>\n"
            case .system:
                // Already handled above
                break
            }
        }

        prompt += "<|im_start|>assistant\n"
        return prompt
    }
}
