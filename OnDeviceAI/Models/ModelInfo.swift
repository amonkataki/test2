import Foundation

struct ModelInfo: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let downloadURL: String
    let sizeBytes: Int64
    let family: ModelFamily
    let parameterCount: String
    let quantization: String
    let description: String

    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

enum ModelFamily: String, Codable, CaseIterable {
    case llama = "Llama"
    case phi = "Phi"
    case mistral = "Mistral"
    case gemma = "Gemma"
    case qwen = "Qwen"
    case stableLM = "StableLM"
    case yi = "Yi"
    case tinyLlama = "TinyLlama"
    case deepseek = "DeepSeek"

    var color: String {
        switch self {
        case .llama: return "blue"
        case .phi: return "green"
        case .mistral: return "orange"
        case .gemma: return "purple"
        case .qwen: return "red"
        case .stableLM: return "teal"
        case .yi: return "indigo"
        case .tinyLlama: return "pink"
        case .deepseek: return "cyan"
        }
    }
}

enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case error(String)
}

extension ModelInfo {
    static let catalog: [ModelInfo] = [
        // TinyLlama - smallest, good for testing
        ModelInfo(
            id: "tinyllama-1.1b-q4",
            name: "TinyLlama 1.1B",
            fileName: "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
            sizeBytes: 669_000_000,
            family: .tinyLlama,
            parameterCount: "1.1B",
            quantization: "Q4_K_M",
            description: "Smallest model, very fast. Good for simple tasks and testing."
        ),
        // Phi-2
        ModelInfo(
            id: "phi-2-3b-q4",
            name: "Phi-2 3B",
            fileName: "phi-2.Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf",
            sizeBytes: 1_790_000_000,
            family: .phi,
            parameterCount: "2.7B",
            quantization: "Q4_K_M",
            description: "Microsoft's compact model with strong reasoning capabilities."
        ),
        // StableLM 3B
        ModelInfo(
            id: "stablelm-zephyr-3b-q4",
            name: "StableLM Zephyr 3B",
            fileName: "stablelm-zephyr-3b.Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/TheBloke/stablelm-zephyr-3b-GGUF/resolve/main/stablelm-zephyr-3b.Q4_K_M.gguf",
            sizeBytes: 1_790_000_000,
            family: .stableLM,
            parameterCount: "3B",
            quantization: "Q4_K_M",
            description: "Stability AI's efficient chat model."
        ),
        // Phi-3 Mini
        ModelInfo(
            id: "phi-3-mini-3.8b-q4",
            name: "Phi-3 Mini 3.8B",
            fileName: "Phi-3-mini-4k-instruct-q4.gguf",
            downloadURL: "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
            sizeBytes: 2_390_000_000,
            family: .phi,
            parameterCount: "3.8B",
            quantization: "Q4_0",
            description: "Microsoft's latest small model. Excellent for its size."
        ),
        // Gemma 2 2B
        ModelInfo(
            id: "gemma-2-2b-q4",
            name: "Gemma 2 2B",
            fileName: "gemma-2-2b-it-Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf",
            sizeBytes: 1_630_000_000,
            family: .gemma,
            parameterCount: "2B",
            quantization: "Q4_K_M",
            description: "Google's lightweight model with good instruction following."
        ),
        // Qwen 2.5 Coder 3B
        ModelInfo(
            id: "qwen2.5-coder-3b-q4",
            name: "Qwen 2.5 Coder 3B",
            fileName: "qwen2.5-coder-3b-instruct-q4_k_m.gguf",
            downloadURL: "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf",
            sizeBytes: 2_060_000_000,
            family: .qwen,
            parameterCount: "3B",
            quantization: "Q4_K_M",
            description: "Specialized for code generation and understanding."
        ),
        // Qwen 2.5 7B
        ModelInfo(
            id: "qwen2.5-7b-q4",
            name: "Qwen 2.5 7B",
            fileName: "qwen2.5-7b-instruct-q4_k_m.gguf",
            downloadURL: "https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf",
            sizeBytes: 4_680_000_000,
            family: .qwen,
            parameterCount: "7B",
            quantization: "Q4_K_M",
            description: "Alibaba's powerful general-purpose model."
        ),
        // Yi 6B
        ModelInfo(
            id: "yi-6b-q4",
            name: "Yi 6B",
            fileName: "yi-6b-chat.Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/TheBloke/Yi-6B-Chat-GGUF/resolve/main/yi-6b-chat.Q4_K_M.gguf",
            sizeBytes: 3_800_000_000,
            family: .yi,
            parameterCount: "6B",
            quantization: "Q4_K_M",
            description: "01.AI's bilingual model (English & Chinese)."
        ),
        // Llama 2 7B
        ModelInfo(
            id: "llama-2-7b-q4",
            name: "Llama 2 7B Chat",
            fileName: "llama-2-7b-chat.Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf",
            sizeBytes: 4_080_000_000,
            family: .llama,
            parameterCount: "7B",
            quantization: "Q4_K_M",
            description: "Meta's foundational chat model. Reliable and well-tested."
        ),
        // Mistral 7B
        ModelInfo(
            id: "mistral-7b-q4",
            name: "Mistral 7B Instruct",
            fileName: "mistral-7b-instruct-v0.2.Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
            sizeBytes: 4_370_000_000,
            family: .mistral,
            parameterCount: "7B",
            quantization: "Q4_K_M",
            description: "Mistral AI's efficient model. Excellent performance for its size."
        ),
        // Meta Llama 3 8B
        ModelInfo(
            id: "llama-3-8b-q4",
            name: "Meta Llama 3 8B",
            fileName: "Meta-Llama-3-8B-Instruct-Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/bartowski/Meta-Llama-3-8B-Instruct-GGUF/resolve/main/Meta-Llama-3-8B-Instruct-Q4_K_M.gguf",
            sizeBytes: 4_920_000_000,
            family: .llama,
            parameterCount: "8B",
            quantization: "Q4_K_M",
            description: "Meta's latest Llama 3. Major improvement over Llama 2."
        ),
        // Meta Llama 3.1 8B
        ModelInfo(
            id: "llama-3.1-8b-q4",
            name: "Meta Llama 3.1 8B",
            fileName: "Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/bartowski/Meta-Llama-3.1-8B-Instruct-GGUF/resolve/main/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
            sizeBytes: 4_920_000_000,
            family: .llama,
            parameterCount: "8B",
            quantization: "Q4_K_M",
            description: "Latest Llama 3.1 with improved multilingual and tool use."
        ),
        // Llama 3.2 3B
        ModelInfo(
            id: "llama-3.2-3b-q4",
            name: "Llama 3.2 3B",
            fileName: "Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf",
            sizeBytes: 2_020_000_000,
            family: .llama,
            parameterCount: "3B",
            quantization: "Q4_K_M",
            description: "Meta's compact Llama 3.2, optimized for mobile devices."
        ),
        // DeepSeek R1 Distill
        ModelInfo(
            id: "deepseek-r1-distill-qwen-1.5b-q4",
            name: "DeepSeek R1 Distill 1.5B",
            fileName: "DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
            downloadURL: "https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf",
            sizeBytes: 1_120_000_000,
            family: .deepseek,
            parameterCount: "1.5B",
            quantization: "Q4_K_M",
            description: "DeepSeek's distilled reasoning model. Strong for its size."
        ),
    ]
}
