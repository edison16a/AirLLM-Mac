import SwiftUI

/// A new chat: the logo, a status line and the message box in the middle of the window.
/// The status line doubles as the place to see loading progress and backend errors.
struct EmptyChatView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            AirLLMLogo(height: 110)
                .opacity(0.95)
                .padding(.bottom, 22)
            status
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.bottom, 26)
            Composer()
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder private var status: some View {
        switch state.backend.status {
        case .ready:
            Text("What's on your mind?")
        case .loading(let model):
            VStack(spacing: 8) {
                Text("Loading \(ModelCatalog.displayName(model))…")
                Text(state.backend.log.last ?? "")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 460)
            }
        case .starting:
            Text("Starting AirLLM…")
        case .failed(let error):
            VStack(spacing: 10) {
                Text(error).font(.callout).multilineTextAlignment(.center).frame(maxWidth: 460)
                Button("Restart Backend") { state.backend.restart() }
            }
        case .noModel, .stopped:
            VStack(spacing: 12) {
                if let error = state.backend.loadError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                        .textSelection(.enabled)
                }
                Button("Choose a model") { state.showModelPicker = true }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }
}
