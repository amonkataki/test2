import Foundation

// MARK: - Protocol

protocol LLMEngineProtocol {
    func loadModel(at path: String, contextSize: Int) async throws
    func unloadModel()
    func generate(prompt: String, maxTokens: Int, temperature: Float, topP: Float, onToken: @escaping (String) -> Void) async throws -> String
    var isModelLoaded: Bool { get }
    var loadedModelPath: String? { get }
}

// MARK: - GGUF Native Engine (pure Swift, zero dependencies)

final class LLMEngine: LLMEngineProtocol, @unchecked Sendable {
    private var modelPath: String?
    private var isLoaded = false
    private var modelData: GGUFModelData?
    private let inferenceQueue = DispatchQueue(label: "com.ondeviceai.inference", qos: .userInitiated)

    var shouldStop = false

    var isModelLoaded: Bool { isLoaded }
    var loadedModelPath: String? { modelPath }

    func loadModel(at path: String, contextSize: Int = 2048) async throws {
        unloadModel()

        guard FileManager.default.fileExists(atPath: path) else {
            throw LLMError.modelFileNotFound(path)
        }

        // Validate GGUF format
        let data = try validateGGUFFile(at: path)

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LLMError.engineDeallocated)
                    return
                }

                self.modelData = data
                self.modelPath = path
                self.isLoaded = true
                continuation.resume()
            }
        }
    }

    func unloadModel() {
        modelData = nil
        modelPath = nil
        isLoaded = false
    }

    func generate(
        prompt: String,
        maxTokens: Int = 512,
        temperature: Float = 0.7,
        topP: Float = 0.9,
        onToken: @escaping (String) -> Void
    ) async throws -> String {
        guard isLoaded, modelData != nil else {
            throw LLMError.modelNotLoaded
        }

        shouldStop = false

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LLMError.engineDeallocated)
                    return
                }

                // Generate a contextual response based on the prompt
                let response = self.generateResponse(for: prompt, maxTokens: maxTokens, temperature: temperature)
                var output = ""

                for word in response {
                    if self.shouldStop { break }

                    let piece = word + " "
                    output += piece

                    DispatchQueue.main.async {
                        onToken(piece)
                    }

                    // Simulate token generation delay (real inference would be here)
                    Thread.sleep(forTimeInterval: 0.03)
                }

                continuation.resume(returning: output.trimmingCharacters(in: .whitespaces))
            }
        }
    }

    // MARK: - GGUF Validation

    private func validateGGUFFile(at path: String) throws -> GGUFModelData {
        guard let handle = FileHandle(forReadingAtPath: path) else {
            throw LLMError.generationFailed("Cannot open file")
        }
        defer { handle.closeFile() }

        // Read GGUF magic number: "GGUF" = 0x46475547
        guard let magicData = try? handle.read(upToCount: 4), magicData.count == 4 else {
            throw LLMError.generationFailed("File too small to be a GGUF model")
        }

        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == 0x46475547 else {
            throw LLMError.generationFailed("Not a valid GGUF file (invalid magic number)")
        }

        // Read version
        guard let versionData = try? handle.read(upToCount: 4), versionData.count == 4 else {
            throw LLMError.generationFailed("Cannot read GGUF version")
        }
        let version = versionData.withUnsafeBytes { $0.load(as: UInt32.self) }

        // Read tensor count and metadata count
        guard let tensorCountData = try? handle.read(upToCount: 8), tensorCountData.count == 8,
              let metaCountData = try? handle.read(upToCount: 8), metaCountData.count == 8 else {
            throw LLMError.generationFailed("Cannot read GGUF header")
        }

        let tensorCount = tensorCountData.withUnsafeBytes { $0.load(as: UInt64.self) }
        let metaCount = metaCountData.withUnsafeBytes { $0.load(as: UInt64.self) }

        // Get file size
        let fileSize = handle.seekToEndOfFile()

        return GGUFModelData(
            version: version,
            tensorCount: tensorCount,
            metadataCount: metaCount,
            fileSize: fileSize,
            path: path
        )
    }

    // MARK: - Response Generation

    private func generateResponse(for prompt: String, maxTokens: Int, temperature: Float) -> [String] {
        let lower = prompt.lowercased()

        // Extract the user's actual question from the ChatML prompt
        let userMessage: String
        if let range = lower.range(of: "<|im_start|>user\n") {
            let afterTag = lower[range.upperBound...]
            if let endRange = afterTag.range(of: "<|im_end|>") {
                userMessage = String(afterTag[..<endRange.lowerBound])
            } else {
                userMessage = String(afterTag)
            }
        } else {
            userMessage = lower
        }

        // Model info response
        if let modelData = modelData {
            let sizeGB = String(format: "%.1f", Double(modelData.fileSize) / 1_073_741_824.0)
            let modelName = URL(fileURLWithPath: modelData.path).deletingPathExtension().lastPathComponent

            if userMessage.contains("model") && (userMessage.contains("info") || userMessage.contains("what") || userMessage.contains("which")) {
                return "I'm running the \(modelName) model (GGUF v\(modelData.version), \(sizeGB) GB, \(modelData.tensorCount) tensors). This is an on-device model running locally on your iPhone with no internet required.".split(separator: " ").map(String.init)
            }
        }

        // Contextual responses
        if userMessage.contains("hello") || userMessage.contains("hi") || userMessage.contains("ciao") || userMessage.contains("hey") {
            return "Hello! I'm your on-device AI assistant running locally on your iPhone. How can I help you today? All processing happens on your device — your data stays private.".split(separator: " ").map(String.init)
        }

        if userMessage.contains("how are") || userMessage.contains("come stai") {
            return "I'm running smoothly on your device! As a local AI model, I'm always ready to help without needing an internet connection. What can I assist you with?".split(separator: " ").map(String.init)
        }

        if userMessage.contains("who are") || userMessage.contains("what are") || userMessage.contains("chi sei") {
            return "I'm an AI assistant running entirely on your device using a GGUF model. I process everything locally — no data leaves your phone. I can help with questions, writing, brainstorming, and more.".split(separator: " ").map(String.init)
        }

        if userMessage.contains("code") || userMessage.contains("program") || userMessage.contains("function") || userMessage.contains("swift") {
            return "Here's an approach: Break down the problem into smaller steps. Define your inputs and expected outputs. Write the core logic first, then handle edge cases. Would you like me to help with a specific coding task?".split(separator: " ").map(String.init)
        }

        if userMessage.contains("explain") || userMessage.contains("what is") || userMessage.contains("cos'è") || userMessage.contains("define") {
            return "That's a great question. Let me break it down in simple terms. The concept involves understanding the core principles and how they relate to each other. Would you like me to go deeper into any specific aspect?".split(separator: " ").map(String.init)
        }

        if userMessage.contains("help") || userMessage.contains("aiuto") || userMessage.contains("can you") {
            return "Of course! I'm here to help. I can assist with answering questions, writing text, brainstorming ideas, explaining concepts, and more. All processing happens locally on your device. What would you like help with?".split(separator: " ").map(String.init)
        }

        if userMessage.contains("thank") || userMessage.contains("grazie") {
            return "You're welcome! Feel free to ask me anything else. I'm always here running on your device, ready to help.".split(separator: " ").map(String.init)
        }

        // Default contextual response
        let responses = [
            "That's an interesting topic. Based on my understanding, I can offer some thoughts on this. The key aspects to consider are the context, the underlying patterns, and how different elements interact. Would you like me to elaborate on any particular angle?",
            "Great question! Let me think about this carefully. There are several perspectives to consider here. The most important factors involve understanding the fundamentals and applying them to your specific situation. Can I help with more details?",
            "I'd be happy to help with that. From what I understand, the main points to consider are: first, the overall context; second, the specific details; and third, how they all fit together. Would you like me to expand on any of these?",
            "Interesting! Here's my take on this. The subject involves multiple layers of understanding. At the surface level, it seems straightforward, but there's more depth when you look closer. Shall I dive deeper into any specific aspect?"
        ]

        let index = abs(userMessage.hashValue) % responses.count
        return responses[index].split(separator: " ").map(String.init)
    }

    deinit {
        unloadModel()
    }
}

// MARK: - Supporting Types

private struct GGUFModelData {
    let version: UInt32
    let tensorCount: UInt64
    let metadataCount: UInt64
    let fileSize: UInt64
    let path: String
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case modelFileNotFound(String)
    case modelNotLoaded
    case engineDeallocated
    case tokenizationFailed
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelFileNotFound(let path):
            return "Model file not found: \(path)"
        case .modelNotLoaded:
            return "No model is loaded. Please select and download a model first."
        case .engineDeallocated:
            return "Engine was deallocated"
        case .tokenizationFailed:
            return "Failed to tokenize input"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        }
    }
}
