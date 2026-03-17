import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false
    var onRegenerate: (() -> Void)?
    var onDelete: (() -> Void)?

    @StateObject private var themeManager = ThemeManager.shared
    @State private var showActions = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Role label
                HStack(spacing: 4) {
                    if message.role == .assistant {
                        Image(systemName: "brain")
                            .font(.caption2)
                            .foregroundStyle(themeManager.accentColor)
                    }
                    Text(message.role == .user ? "You" : "Assistant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Message content
                Text(message.content.isEmpty ? " " : message.content)
                    .font(.body)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user
                            ? AnyShapeStyle(themeManager.accentColor.opacity(0.85))
                            : AnyShapeStyle(.gray.opacity(0.15))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        if isStreaming {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                        }
                    }

                // Streaming indicator
                if isStreaming {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Generating...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Action buttons
                if !isStreaming && showActions {
                    actionButtons
                }
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showActions.toggle()
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                UIPasteboard.general.string = message.content
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption2)
            }

            if let onRegenerate = onRegenerate {
                Button(action: onRegenerate) {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .font(.caption2)
                }
            }

            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.caption2)
                }
            }
        }
        .foregroundStyle(.secondary)
        .padding(.top, 2)
    }
}
