import SwiftUI

/// The toolbar control showing the loaded model. Clicking it opens the picker.
struct ModelPickerButton: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Button { state.showModelPicker = true } label: {
            HStack(spacing: 7) {
                label
                if state.backend.isMock {
                    Text("DEMO").font(.caption2.bold()).foregroundStyle(.orange)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Choose a model (⇧⌘M)")
    }

    @ViewBuilder private var label: some View {
        switch state.backend.status {
        case .ready(let model, _):
            ProviderLogo(name: ModelCatalog.logo(for: model), size: 16)
            Text(ModelCatalog.displayName(model)).fontWeight(.medium)
        case .loading(let model):
            ProgressView().controlSize(.small).scaleEffect(0.8)
            Text("Loading \(ModelCatalog.displayName(model))…").foregroundStyle(.secondary)
        case .starting:
            ProgressView().controlSize(.small).scaleEffect(0.8)
            Text("Starting…").foregroundStyle(.secondary)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text("Backend error")
        case .noModel, .stopped:
            Text("Choose a model").foregroundStyle(.secondary)
        }
    }
}
