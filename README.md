<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017+-blue?logo=apple" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/Engine-llama.cpp-green" alt="Engine">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License">
</p>

# LocalLLM - Private AI Chat for iOS

> Created by **Ali Moustafa** — [mustafa30102001@gmail.com](mailto:mustafa30102001@gmail.com)

Run large language models **entirely on your iPhone or iPad**. No internet required, no subscriptions, no data leaves your device.

LocalLLM uses [llama.cpp](https://github.com/ggerganov/llama.cpp) with Metal GPU acceleration to run GGUF models locally on Apple Silicon, delivering fast and private AI conversations.

---

## Features

- **100% On-Device Inference** - All processing happens locally using Metal GPU acceleration
- **14+ Open Source Models** - Download and switch between models from the built-in catalog
- **Streaming Responses** - See tokens appear in real-time as the model generates
- **Conversation History** - All chats are persisted locally with SwiftData
- **Model Management** - Download, delete, and switch models with background downloads
- **Customizable Generation** - Adjust temperature, top-p, max tokens, and context size
- **Custom System Prompts** - Define how the AI assistant behaves
- **Theme Support** - Light, dark, and system themes with 8 accent color options
- **Privacy First** - Zero network calls during inference, all data stays on device
- **Universal App** - Optimized for both iPhone and iPad with adaptive layouts

## Supported Models

| Model | Parameters | Size (Q4) | Best For |
|-------|-----------|-----------|----------|
| TinyLlama 1.1B | 1.1B | ~670 MB | Quick responses, testing |
| DeepSeek R1 Distill | 1.5B | ~1.1 GB | Reasoning tasks |
| Gemma 2 2B | 2B | ~1.6 GB | Instruction following |
| Phi-2 | 2.7B | ~1.8 GB | Reasoning, code |
| StableLM Zephyr 3B | 3B | ~1.8 GB | General chat |
| Llama 3.2 3B | 3B | ~2.0 GB | Mobile-optimized chat |
| Qwen 2.5 Coder 3B | 3B | ~2.1 GB | Code generation |
| Phi-3 Mini 3.8B | 3.8B | ~2.4 GB | Best small model |
| Yi 6B | 6B | ~3.8 GB | Bilingual (EN/ZH) |
| Llama 2 7B Chat | 7B | ~4.1 GB | Reliable general chat |
| Mistral 7B Instruct | 7B | ~4.4 GB | High quality responses |
| Qwen 2.5 7B | 7B | ~4.7 GB | General purpose |
| Meta Llama 3 8B | 8B | ~4.9 GB | Latest generation |
| Meta Llama 3.1 8B | 8B | ~4.9 GB | Multilingual, tool use |

> **Note:** 7B+ models require iPhone 15 Pro / iPad with M-series chip (8+ GB RAM).
> Smaller models (1-3B) run well on iPhone 12+ and most iPads.

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Physical device recommended (Metal GPU acceleration)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/LocalLLM.git
cd LocalLLM
```

### 2. Open in Xcode

```bash
open LocalLLM.xcodeproj
```

### 3. Configure Signing

1. Select the **LocalLLM** target
2. Go to **Signing & Capabilities**
3. Select your **Development Team**
4. Update the **Bundle Identifier** if needed

### 4. Add llama.cpp Dependency

The project uses [llama.cpp](https://github.com/ggerganov/llama.cpp) via Swift Package Manager:

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter: `https://github.com/ggerganov/llama.cpp`
3. Select the `llama` product
4. Add to the **LocalLLM** target

### 5. Build & Run

Select your physical device and press **Cmd+R**.

> The app works on Simulator but inference performance requires a physical device with Metal support.

## Architecture

```
LocalLLM/
├── App/
│   ├── LocalLLMApp.swift          # App entry point, SwiftData container
│   └── ContentView.swift          # Root TabView with theme support
├── Models/
│   ├── ChatMessage.swift          # SwiftData message model
│   ├── Conversation.swift         # SwiftData conversation model
│   └── ModelInfo.swift            # Model catalog definitions
├── Services/
│   ├── LLMEngine.swift            # llama.cpp inference bridge
│   ├── LLMService.swift           # High-level inference orchestration
│   ├── ModelManager.swift         # Downloaded model management
│   ├── DownloadManager.swift      # Background download handling
│   └── ThemeManager.swift         # Theme & accent color management
├── ViewModels/
│   ├── ChatViewModel.swift        # Chat logic & state
│   └── ModelCatalogViewModel.swift # Catalog filtering & actions
└── Views/
    ├── Chat/
    │   ├── ChatView.swift         # Main chat interface
    │   ├── MessageBubble.swift    # Message bubble component
    │   ├── ConversationListView.swift # Sidebar conversation list
    │   └── ModelSelectorView.swift    # In-chat model picker
    ├── ModelCatalog/
    │   └── ModelCatalogView.swift # Model download catalog
    └── Settings/
        └── SettingsView.swift     # App settings & theme picker
```

### Key Design Decisions

- **SwiftData** for conversation persistence (iOS 17+)
- **MVVM** architecture with `@Observable` / `ObservableObject`
- **llama.cpp** for inference (C++ library with Swift bridge)
- **Metal** GPU acceleration for fast token generation
- **URLSession background downloads** for model files
- **ChatML prompt format** for broad model compatibility

## Customization

### Adding New Models

Edit `LocalLLM/Models/ModelInfo.swift` and add entries to the `catalog` array:

```swift
ModelInfo(
    id: "your-model-id",
    name: "Your Model Name",
    fileName: "model-file.gguf",
    downloadURL: "https://huggingface.co/.../model-file.gguf",
    sizeBytes: 4_000_000_000,
    family: .llama,
    parameterCount: "7B",
    quantization: "Q4_K_M",
    description: "Description of the model."
)
```

### Connecting llama.cpp

The `LLMEngine.swift` file contains commented-out llama.cpp integration code. To enable real inference:

1. Add the llama.cpp Swift package dependency
2. Import llama in `LLMEngine.swift`
3. Uncomment the llama.cpp calls in `loadModel()` and `generate()`
4. Build with the `llama` product linked

## Performance Tips

- Use **Q4_K_M** quantization for the best balance of quality and speed
- Start with **smaller models** (1-3B) to verify your setup
- Set **context size to 2048** or lower for faster inference
- Close other apps to free RAM for larger models
- **iPhone 15 Pro** and **M-series iPads** offer the best experience

## Privacy

LocalLLM is designed with privacy as a core principle:

- All AI inference runs **entirely on-device**
- No data is sent to any server
- No analytics or tracking
- No account required
- Conversations are stored locally in SwiftData
- Models are downloaded from HuggingFace (the only network call)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Author

**Ali Moustafa** — [mustafa30102001@gmail.com](mailto:mustafa30102001@gmail.com)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - C/C++ LLM inference engine by Georgi Gerganov
- [HuggingFace](https://huggingface.co) - Model hosting and community
- [Meta AI](https://ai.meta.com) - Llama model family
- [Mistral AI](https://mistral.ai) - Mistral models
- [Microsoft](https://microsoft.com) - Phi model family
- [Google](https://ai.google) - Gemma models
- [Alibaba](https://qwenlm.github.io) - Qwen models
- [DeepSeek](https://deepseek.com) - DeepSeek R1
