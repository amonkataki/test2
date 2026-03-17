import SwiftUI

struct ModelCatalogView: View {
    @StateObject private var viewModel = ModelCatalogViewModel()
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var modelManager = ModelManager.shared

    var body: some View {
        NavigationStack {
            List {
                // Family filter
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: viewModel.selectedFamily == nil
                            ) {
                                viewModel.selectedFamily = nil
                            }

                            ForEach(viewModel.families, id: \.self) { family in
                                FilterChip(
                                    title: family.rawValue,
                                    isSelected: viewModel.selectedFamily == family
                                ) {
                                    viewModel.selectedFamily = family
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                }

                // Downloaded models
                let downloaded = viewModel.filteredModels.filter { modelManager.downloadedModels.contains($0) }
                if !downloaded.isEmpty {
                    Section("Downloaded") {
                        ForEach(downloaded) { model in
                            ModelCatalogRow(
                                model: model,
                                downloadState: viewModel.downloadState(for: model),
                                isSelected: modelManager.selectedModelId == model.id,
                                onDownload: { viewModel.downloadModel(model) },
                                onCancel: { viewModel.cancelDownload(model) },
                                onDelete: { viewModel.deleteModel(model) },
                                onSelect: { viewModel.selectModel(model) }
                            )
                        }
                    }
                }

                // Available models
                let available = viewModel.filteredModels.filter { !modelManager.downloadedModels.contains($0) }
                if !available.isEmpty {
                    Section("Available to Download") {
                        ForEach(available) { model in
                            ModelCatalogRow(
                                model: model,
                                downloadState: viewModel.downloadState(for: model),
                                isSelected: false,
                                onDownload: { viewModel.downloadModel(model) },
                                onCancel: { viewModel.cancelDownload(model) },
                                onDelete: { viewModel.deleteModel(model) },
                                onSelect: { viewModel.selectModel(model) }
                            )
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search models...")
            .navigationTitle("Downloadable Models")
        }
    }
}

// MARK: - Model Row

struct ModelCatalogRow: View {
    let model: ModelInfo
    let downloadState: ModelDownloadState
    let isSelected: Bool
    let onDownload: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .font(.headline)

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(themeManager.accentColor)
                        }
                    }

                    HStack(spacing: 8) {
                        Label(model.family.rawValue, systemImage: "cpu")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(themeManager.accentColor.opacity(0.15))
                            .clipShape(Capsule())

                        Text(model.parameterCount)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(model.quantization)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(model.sizeFormatted)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                actionButton
            }

            Text(model.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Download progress
            if case .downloading(let progress) = downloadState {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .tint(themeManager.accentColor)

                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch downloadState {
        case .notDownloaded:
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.title2)
                    .foregroundStyle(themeManager.accentColor)
            }
            .buttonStyle(.plain)

        case .downloading:
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)

        case .downloaded:
            Menu {
                Button(action: onSelect) {
                    Label("Use This Model", systemImage: "checkmark.circle")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Model", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(themeManager.accentColor)
            }

        case .error:
            Button(action: onDownload) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? themeManager.accentColor : .gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
