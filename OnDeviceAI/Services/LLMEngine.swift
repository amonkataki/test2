import Foundation
import llama

protocol LLMEngineProtocol {
    func loadModel(at path: String, contextSize: Int) async throws
    func unloadModel()
    func generate(prompt: String, maxTokens: Int, temperature: Float, topP: Float, onToken: @escaping (String) -> Void) async throws -> String
    var isModelLoaded: Bool { get }
    var loadedModelPath: String? { get }
}

final class LLMEngine: LLMEngineProtocol {
    private var modelPath: String?
    private var isLoaded = false
    private let inferenceQueue = DispatchQueue(label: "com.ondeviceai.inference", qos: .userInitiated)

    private var model: OpaquePointer?
    private var context: OpaquePointer?

    var shouldStop = false

    var isModelLoaded: Bool { isLoaded }
    var loadedModelPath: String? { modelPath }

    func loadModel(at path: String, contextSize: Int = 2048) async throws {
        unloadModel()

        guard FileManager.default.fileExists(atPath: path) else {
            throw LLMError.modelFileNotFound(path)
        }

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LLMError.engineDeallocated)
                    return
                }

                // Initialize llama backend (safe to call multiple times)
                llama_backend_init()

                // Load model
                var modelParams = llama_model_default_params()
                modelParams.n_gpu_layers = 99 // Use Metal GPU fully

                guard let loadedModel = llama_load_model_from_file(path, modelParams) else {
                    continuation.resume(throwing: LLMError.generationFailed("Failed to load model from: \(path)"))
                    return
                }

                // Create context
                var ctxParams = llama_context_default_params()
                ctxParams.n_ctx = UInt32(contextSize)
                ctxParams.n_batch = 512
                ctxParams.n_threads = UInt32(max(1, ProcessInfo.processInfo.activeProcessorCount - 1))
                ctxParams.n_threads_batch = UInt32(max(1, ProcessInfo.processInfo.activeProcessorCount - 1))

                guard let ctx = llama_new_context_with_model(loadedModel, ctxParams) else {
                    llama_free_model(loadedModel)
                    continuation.resume(throwing: LLMError.generationFailed("Failed to create context"))
                    return
                }

                self.model = loadedModel
                self.context = ctx
                self.modelPath = path
                self.isLoaded = true
                continuation.resume()
            }
        }
    }

    func unloadModel() {
        if let ctx = context {
            llama_free(ctx)
        }
        if let m = model {
            llama_free_model(m)
        }
        context = nil
        model = nil
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
        guard isLoaded, let model = self.model, let context = self.context else {
            throw LLMError.modelNotLoaded
        }

        shouldStop = false

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: LLMError.engineDeallocated)
                    return
                }

                // Clear KV cache for new generation
                llama_kv_cache_clear(context)

                // Tokenize the prompt
                let promptCStr = prompt.cString(using: .utf8)!
                let maxTokenCount = prompt.count + 256
                var tokens = [llama_token](repeating: 0, count: maxTokenCount)
                let nTokens = llama_tokenize(model, promptCStr, Int32(promptCStr.count - 1), &tokens, Int32(maxTokenCount), true, false)

                guard nTokens > 0 else {
                    continuation.resume(throwing: LLMError.tokenizationFailed)
                    return
                }

                let promptTokens = Array(tokens.prefix(Int(nTokens)))

                // Evaluate prompt tokens in batches
                var batch = llama_batch_init(512, 0, 1)
                var nPast: Int32 = 0

                // Process prompt in chunks
                let batchSize = 512
                for i in stride(from: 0, to: promptTokens.count, by: batchSize) {
                    let end = min(i + batchSize, promptTokens.count)
                    let chunk = Array(promptTokens[i..<end])

                    llama_batch_clear(&batch)
                    for (j, token) in chunk.enumerated() {
                        llama_batch_add(&batch, token, nPast + Int32(j), [0], j == end - 1 - i)
                    }

                    if llama_decode(context, batch) != 0 {
                        llama_batch_free(batch)
                        continuation.resume(throwing: LLMError.generationFailed("Failed to evaluate prompt"))
                        return
                    }
                    nPast += Int32(chunk.count)
                }

                // Setup sampler chain
                let sparams = llama_sampler_chain_default_params()
                let sampler = llama_sampler_chain_init(sparams)

                llama_sampler_chain_add(sampler, llama_sampler_init_top_p(topP, 1))
                llama_sampler_chain_add(sampler, llama_sampler_init_temp(temperature))
                llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32.random(in: 0...UInt32.max)))

                // Generate tokens
                var output = ""
                let eosToken = llama_token_eos(model)

                for _ in 0..<maxTokens {
                    if self.shouldStop { break }

                    // Sample next token
                    let newToken = llama_sampler_sample(sampler, context, -1)

                    // Check for end of sequence
                    if newToken == eosToken || llama_token_is_eog(model, newToken) {
                        break
                    }

                    // Convert token to string
                    let piece = self.tokenToString(model: model, token: newToken)
                    output += piece

                    DispatchQueue.main.async {
                        onToken(piece)
                    }

                    // Evaluate the new token
                    llama_batch_clear(&batch)
                    llama_batch_add(&batch, newToken, nPast, [0], true)

                    if llama_decode(context, batch) != 0 {
                        break
                    }
                    nPast += 1
                }

                llama_sampler_free(sampler)
                llama_batch_free(batch)

                continuation.resume(returning: output)
            }
        }
    }

    private func tokenToString(model: OpaquePointer, token: llama_token) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let n = llama_token_to_piece(model, token, &buffer, 256, 0, false)
        if n > 0 {
            return String(cString: Array(buffer.prefix(Int(n))) + [0])
        }
        return ""
    }

    deinit {
        unloadModel()
    }
}

// MARK: - llama_batch helpers

private func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

private func llama_batch_add(_ batch: inout llama_batch, _ token: llama_token, _ pos: Int32, _ seqIds: [Int32], _ logits: Bool) {
    let i = Int(batch.n_tokens)
    batch.token[i] = token
    batch.pos[i] = pos
    batch.n_seq_id[i] = Int32(seqIds.count)
    for (j, id) in seqIds.enumerated() {
        batch.seq_id[i]![j] = id
    }
    batch.logits[i] = logits ? 1 : 0
    batch.n_tokens += 1
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
            return "No model is loaded"
        case .engineDeallocated:
            return "Engine was deallocated"
        case .tokenizationFailed:
            return "Failed to tokenize input"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        }
    }
}
