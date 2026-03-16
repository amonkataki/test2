# Contributing to LocalLLM

Thank you for your interest in contributing to LocalLLM! This guide will help you get started.

## How to Contribute

### Reporting Bugs

1. Check existing [Issues](../../issues) to avoid duplicates
2. Create a new issue with:
   - Device model and iOS version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots or logs if applicable

### Suggesting Features

Open an issue with the **feature request** label. Include:
- A clear description of the feature
- Why it would be useful
- Any implementation ideas

### Submitting Code

1. **Fork** the repository
2. Create a **feature branch**: `git checkout -b feature/your-feature`
3. Make your changes following the code style below
4. **Test** on a physical device
5. **Commit** with clear messages: `git commit -m "feat: add model search filtering"`
6. **Push** to your fork: `git push origin feature/your-feature`
7. Open a **Pull Request** against `main`

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI for all UI code
- Use MVVM architecture (Views, ViewModels, Services)
- Keep files focused and under 300 lines when possible
- Use `@MainActor` for all UI-related classes
- Prefer `async/await` over completion handlers

### Naming Conventions

- **Views**: `ChatView.swift`, `ModelCatalogView.swift`
- **ViewModels**: `ChatViewModel.swift`
- **Services**: `LLMService.swift`, `ModelManager.swift`
- **Models**: `ChatMessage.swift`, `Conversation.swift`

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new model to catalog
fix: resolve crash when switching models
refactor: simplify download manager logic
docs: update README with new models
```

## Adding New Models

To add a new model to the catalog:

1. Find a GGUF-quantized version on HuggingFace
2. Prefer Q4_K_M quantization for mobile
3. Test the model on an actual device
4. Add the entry to `ModelInfo.catalog` in `LocalLLM/Models/ModelInfo.swift`
5. Verify the download URL works

## Development Setup

1. Xcode 15.0+
2. Physical iOS device (iPhone 12+ or iPad with A14+ chip)
3. Apple Developer account (for device testing)

## Contact

For questions about contributing, reach out to **Ali Moustafa** at [mustafa30102001@gmail.com](mailto:mustafa30102001@gmail.com).

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
