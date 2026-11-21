import SwiftUI

/// The model sheet. It shows what this Mac has, rates every catalog model
/// against it, and loads the chosen one.
struct ModelPicker: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var selected = ""
    @State private var onlyRunnable = false
    @State private var token = ""

    var body: some View {
        let info = state.systemInfo
        VStack(spacing: 0) {
            header(info)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(models(info)) { model in
                        ModelRow(model: model, report: FitAnalyzer.report(for: model, settings: state.settings, info: info),
                                 info: info, selected: selected == model.repo, loaded: state.backend.modelID == model.repo)
                            .onTapGesture(count: 2) { selected = model.repo; load() }
                            .onTapGesture { selected = model.repo }
                    }
                    CustomModelSection(selected: $selected, token: $token, info: info).padding(.top, 14)
                    if state.backend.status.isLoading || state.backend.loadError != nil {
                        LoadStatusView().padding(.top, 14)
                    }
                }
                .padding(16)
            }
            Divider()
            footer
        }
        .frame(width: 680)
        .frame(minHeight: 420, idealHeight: 600, maxHeight: 600)
        .onAppear {
            state.refreshSystemInfo()
            selected = state.backend.modelID ?? state.settings.lastModel
            if selected.isEmpty { selected = ModelCatalog.all.first?.repo ?? "" }
            token = Keychain.readToken() ?? ""
        }
    }

    private func models(_ info: SystemInfo) -> [CatalogModel] {
        guard onlyRunnable else { return ModelCatalog.all }
        return ModelCatalog.all.filter {
            FitAnalyzer.report(for: $0, settings: state.settings, info: info).level.canRun
        }
    }

    private func header(_ info: SystemInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Models").font(.title2.weight(.semibold))
                Spacer()
                Toggle("Only show models this Mac can run", isOn: $onlyRunnable)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            HStack(spacing: 10) {
                MacStat(icon: "memorychip", value: Format.gigabytes(info.ramGB), label: "memory")
                MacStat(icon: "internaldrive", value: Format.gigabytes(info.freeDiskGB), label: "free disk")
                MacStat(icon: "cpu", value: info.chipName.replacingOccurrences(of: "Apple ", with: ""), label: "chip")
                Spacer()
                InfoButton("AirLLM loads one layer at a time, so even models far bigger than your memory can run. "
                           + "Models that fit in memory run much faster, because macOS keeps them cached after the first token. "
                           + "Bigger models are read from your SSD for every token.")
            }
        }
        .padding(18)
    }

    private var footer: some View {
        HStack {
            if let model = state.backend.modelID {
                Button("Unload") { Task { await state.backend.unload() } }
                    .disabled(state.chat.isGenerating)
                    .help("Free the memory used by \(ModelCatalog.displayName(model))")
            }
            Spacer()
            Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
            Button(loadTitle, action: load)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!canLoad)
        }
        .padding(16)
    }

    private var loadTitle: String {
        if state.backend.status.isLoading { return "Loading…" }
        return state.backend.modelID == selected ? "Reload" : "Use This Model"
    }

    /// Loads are refused while the server is down or busy, rather than queued.
    private var canLoad: Bool {
        guard !state.backend.status.isLoading, !state.chat.isGenerating, !selected.isEmpty else { return false }
        switch state.backend.status {
        case .starting, .failed, .stopped: return false
        default: return true
        }
    }

    private func load() {
        guard canLoad else { return }
        Keychain.writeToken(token.trimmingCharacters(in: .whitespacesAndNewlines))
        state.loadModel(selected)
    }
}

/// Loading progress, or the error from the last load, with the server log.
private struct LoadStatusView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let loading = state.backend.status.isLoading
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if loading { ProgressView().controlSize(.small) }
                Text(loading ? "Loading. The first time, this downloads the model and splits it into layers."
                             : "Couldn't load the model")
                    .font(.callout.weight(.medium))
            }
            if let error = state.backend.loadError {
                Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
            }
            LogView(lines: state.backend.log).frame(height: 130)
        }
    }
}
