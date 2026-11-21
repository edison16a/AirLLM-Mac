import AppKit
import SwiftUI

/// The bottom of the picker: check any Hugging Face repo or pick a local folder,
/// and store a Hugging Face token for gated models.
struct CustomModelSection: View {
    @Environment(AppState.self) private var state
    @Binding var selected: String
    @Binding var token: String
    let info: SystemInfo
    @State private var repo = ""
    @State private var checking = false
    @State private var result: HuggingFaceModelInfo?
    @State private var checkError: String?
    @State private var showToken = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("Any Hugging Face model").font(.headline)
                InfoButton("Paste a repo id like NousResearch/Hermes-3-Llama-3.1-8B and press Check. "
                           + "The app reads the model's config from Hugging Face and tells you whether AirLLM can run it "
                           + "on this Mac, how much disk it needs and roughly how fast it will be. "
                           + "On macOS, AirLLM only runs Llama and Mistral style models.")
            }
            HStack {
                TextField("organization/model-name, or a local folder", text: $repo)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(check)
                Button("Folder…", action: pickFolder)
                Button(checking ? "Checking…" : "Check", action: check)
                    .disabled(trimmedRepo.isEmpty || checking || trimmedRepo.hasPrefix("/"))
            }
            if let checkError {
                Text(checkError).font(.callout).foregroundStyle(.red)
            }
            if let result {
                let model = result.asCatalogModel
                ModelRow(model: model, report: FitAnalyzer.report(for: model, settings: state.settings, info: info),
                         info: info, selected: selected == result.repo, loaded: state.backend.modelID == result.repo,
                         unsupported: !result.supported)
                    .onTapGesture { if result.supported { selected = result.repo } }
            }
            tokenField
        }
        .padding(14)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onAppear {
            if ModelCatalog.entry(selected) == nil { repo = selected }
        }
    }

    private var tokenField: some View {
        DisclosureGroup(isExpanded: $showToken) {
            VStack(alignment: .leading, spacing: 6) {
                SecureField("hf_…", text: $token).textFieldStyle(.roundedBorder)
                Text("Saved in your Keychain. Only the local AirLLM backend sends it, to Hugging Face. "
                     + "Get one at huggingface.co/settings/tokens.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "lock")
                Text(token.isEmpty ? "Hugging Face token" : "Hugging Face token (saved)")
            }
            .font(.callout)
        }
    }

    private var trimmedRepo: String { repo.trimmingCharacters(in: .whitespaces) }

    private func check() {
        let repo = trimmedRepo
        guard !repo.isEmpty, !repo.hasPrefix("/") else { return }
        checking = true
        checkError = nil
        result = nil
        Task {
            do {
                let info = try await HuggingFaceCheck.fetch(repo, token: token)
                result = info
                if info.supported { selected = repo }
            } catch {
                checkError = error.localizedDescription
            }
            checking = false
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Choose a folder with a Llama style model (config.json and safetensors files)"
        if panel.runModal() == .OK, let url = panel.url {
            repo = url.path
            selected = url.path
            result = nil
        }
    }
}
