import AppKit
import SwiftUI

/// Advanced: how much chat history is sent, and where split models are kept.
struct StorageSettingsSection: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Section("Conversation") {
            SettingRow("Remembered exchanges", info: """
                How many recent back and forth turns are sent with each new message. The model only remembers \
                what is sent. More turns make longer prompts, which take longer to read before the reply starts.
                """) {
                Stepper("\(settings.historyTurns)", value: $settings.historyTurns, in: 1...50)
            }
        }
        Section("Storage") {
            SettingRow("Split model folder", info: """
                The first time AirLLM loads a model it splits it into one file per layer. By default these go next to \
                the download in ~/.cache/huggingface. Choose another folder, like an external SSD, to save space on \
                your main drive. A fast drive matters, because every token reads the whole model.
                """) {
                shardsFolder
            }
            SettingRow("Delete original after splitting", info: """
                After AirLLM splits a new model into layers, delete the original download. This roughly halves the disk \
                space each model uses. The catch is that splitting again later, after an AirLLM update say, means downloading again.
                """) {
                Toggle("", isOn: $settings.deleteOriginal).labelsHidden()
            }
            ActionRow("Show Downloaded Models", info: """
                Opens the Hugging Face cache in Finder. Each model is a folder starting with "models--". \
                Delete one to free its space. The app downloads it again if you use it.
                """) {
                NSWorkspace.shared.open(AppPaths.huggingFaceHub)
            }
        }
    }

    private var shardsFolder: some View {
        HStack {
            Text(settings.layerShardsPath.isEmpty
                 ? "Default" : (settings.layerShardsPath as NSString).abbreviatingWithTildeInPath)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Button("Choose…") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.canCreateDirectories = true
                if panel.runModal() == .OK, let url = panel.url { settings.layerShardsPath = url.path }
            }
            if !settings.layerShardsPath.isEmpty {
                Button("Reset") { settings.layerShardsPath = "" }
            }
        }
    }
}
