import SwiftUI

/// The message box, with send and stop buttons and the time estimate below it.
struct Composer: View {
    @Environment(AppState.self) private var state
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .lineLimit(1...10)
                    .focused($focused)
                    .padding(.vertical, 13)
                    .padding(.leading, 18)
                    .onSubmit(send)
                    .disabled(!state.backend.isReady)
                if state.chat.isGenerating {
                    roundButton("stop.fill", size: 11, enabled: true, action: state.chat.stop)
                        .help("Stop (⌘.)")
                } else {
                    roundButton("arrow.up", size: 13, enabled: canSend, action: send)
                        .help("Send (Return)")
                }
            }
            .background(Color(nsColor: .controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.primary.opacity(focused ? 0.18 : 0.1), lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 3)

            EstimateLine()
        }
        .frame(maxWidth: 720)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .onAppear { focused = true }
        .onChange(of: state.library.selection) { _, _ in focused = true }
    }

    private func roundButton(_ symbol: String, size: CGFloat, enabled: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(Color(nsColor: .textBackgroundColor))
                .frame(width: 30, height: 30)
                .background(enabled ? Color.primary : Color.primary.opacity(0.18), in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .padding(8)
    }

    private var placeholder: String {
        guard let model = state.backend.modelID else { return "Load a model to start" }
        return "Message \(ModelCatalog.displayName(model))"
    }

    private var canSend: Bool {
        state.backend.isReady && !state.chat.isGenerating
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        guard canSend else { return }
        state.chat.send(text)
        text = ""
    }
}
