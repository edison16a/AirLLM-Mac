import AppKit
import SwiftUI

/// One message. The user's sit in a bubble on the right; replies run full
/// width beside the model's logo, like a document.
struct MessageRow: View {
    @Environment(AppState.self) private var state
    let message: Message
    let isStreaming: Bool
    let isLast: Bool
    @State private var hovering = false

    var body: some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 120)
                Text(message.content)
                    .textSelection(.enabled)
                    .lineSpacing(2)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(Color.primary.opacity(0.06),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        } else {
            reply
        }
    }

    private var reply: some View {
        HStack(alignment: .top, spacing: 14) {
            ProviderLogo(name: ModelCatalog.logo(for: message.modelID), size: 22)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 10) {
                if !message.content.isEmpty { MarkdownText(message.content) }
                if isStreaming { GenerationStatus(hasText: !message.content.isEmpty) }
                if let error = message.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .textSelection(.enabled)
                }
                if !isStreaming { footer.opacity(hovering || isLast ? 1 : 0) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onHover { hovering = $0 }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(message.content, forType: .string)
            } label: { Image(systemName: "doc.on.doc") }
                .help("Copy")
            if isLast {
                Button { state.chat.regenerate() } label: { Image(systemName: "arrow.clockwise") }
                    .help("Regenerate (⌘R)")
                    .disabled(state.chat.isGenerating || !state.backend.isReady)
            }
            if let stats = message.stats {
                Text(Self.summary(stats)).foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.borderless)
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    /// For example "120 tokens, 2m 4s, 1.0 s/token".
    static func summary(_ stats: GenerationStats) -> String {
        var parts = ["\(stats.tokens) tokens", Format.duration(stats.seconds)]
        if stats.tokens > 1 { parts.append(Format.speed(secondsPerToken: stats.seconds / Double(stats.tokens))) }
        if stats.reason == "stopped" { parts.append("stopped") }
        if stats.reason == "length" { parts.append("hit the length limit") }
        return parts.joined(separator: ", ")
    }
}
