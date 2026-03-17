import SwiftUI

struct SettingsView: View {
    @StateObject private var modelManager = ModelManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("systemPrompt") private var systemPrompt = "You are a helpful AI assistant."
    @AppStorage("maxTokens") private var maxTokens = 512
    @AppStorage("temperature") private var temperature = 0.7
    @AppStorage("topP") private var topP = 0.9
    @AppStorage("contextSize") private var contextSize = 2048

    var body: some View {
        NavigationStack {
            Form {
                // Appearance
                Section("Appearance") {
                    // Theme mode
                    HStack {
                        Label("Theme", systemImage: themeManager.appTheme.icon)
                        Spacer()
                        Picker("", selection: $themeManager.appTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.rawValue).tag(theme)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(themeManager.accentColor)
                    }

                    // Accent color
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Accent Color", systemImage: "paintpalette.fill")

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(AccentColorOption.allCases) { option in
                                Button {
                                    withAnimation {
                                        themeManager.accentColorName = option.rawValue
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(option.color)
                                            .frame(width: 36, height: 36)

                                        if themeManager.accentColorName == option.rawValue {
                                            Circle()
                                                .strokeBorder(.white, lineWidth: 2)
                                                .frame(width: 36, height: 36)

                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Model Info
                Section("Active Model") {
                    if let model = modelManager.selectedModel {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .font(.headline)
                                Text("\(model.parameterCount) \u{2022} \(model.quantization)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(themeManager.accentColor)
                        }
                    } else {
                        Text("No model selected")
                            .foregroundStyle(.secondary)
                    }
                }

                // Generation Parameters
                Section("Generation") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Max Tokens")
                            Spacer()
                            Text("\(maxTokens)")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: .init(
                            get: { Double(maxTokens) },
                            set: { maxTokens = Int($0) }
                        ), in: 64...2048, step: 64)
                        .tint(themeManager.accentColor)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", temperature))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $temperature, in: 0...2, step: 0.05)
                            .tint(themeManager.accentColor)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Top P")
                            Spacer()
                            Text(String(format: "%.2f", topP))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $topP, in: 0...1, step: 0.05)
                            .tint(themeManager.accentColor)
                    }

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Context Size")
                            Spacer()
                            Text("\(contextSize)")
                                .foregroundStyle(.secondary)
                        }
                        Picker("Context Size", selection: $contextSize) {
                            Text("512").tag(512)
                            Text("1024").tag(1024)
                            Text("2048").tag(2048)
                            Text("4096").tag(4096)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // System Prompt
                Section("System Prompt") {
                    TextEditor(text: $systemPrompt)
                        .frame(minHeight: 80)
                        .font(.body)

                    Button("Reset to Default") {
                        systemPrompt = "You are a helpful AI assistant."
                    }
                    .font(.caption)
                }

                // Storage
                Section("Storage") {
                    HStack {
                        Text("Models on Device")
                        Spacer()
                        Text("\(modelManager.downloadedModels.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Disk Usage")
                        Spacer()
                        Text(modelManager.diskUsageFormatted)
                            .foregroundStyle(.secondary)
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Engine")
                        Spacer()
                        Text("llama.cpp")
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("Privacy") {
                        Text("All data stays on device")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
