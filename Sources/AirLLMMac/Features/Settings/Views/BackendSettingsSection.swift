import AppKit
import SwiftUI

/// Advanced: the Python that runs AirLLM, the local port, logging and demo mode.
struct BackendSettingsSection: View {
    @Bindable var settings: AppSettings
    let log: [String]

    var body: some View {
        Section("Backend") {
            SettingRow("Python", info: """
                The Python that runs AirLLM. Setup creates a private one in \
                ~/Library/Application Support/AirLLM Chat/venv. Only point this somewhere else \
                if you manage your own AirLLM install.
                """) {
                HStack {
                    Text((settings.pythonPath as NSString).abbreviatingWithTildeInPath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                    Button("Choose…", action: choosePython)
                }
            }
            SettingRow("Port", info: """
                The app talks to AirLLM through a small server that only accepts connections from this Mac. \
                Change the port only if another app already uses 8765.
                """) {
                TextField("", value: $settings.port, format: .number.grouping(.never))
                    .frame(width: 70)
                    .multilineTextAlignment(.trailing)
            }
            SettingRow("Log memory usage", info: """
                Asks AirLLM to print how much memory each layer uses while it generates. Handy for checking \
                whether a big model is close to your Mac's limit. It shows in the log below and applies from the next model load.
                """) {
                Toggle("", isOn: $settings.showMemoryUtil).labelsHidden()
            }
            SettingRow("Demo mode", info: """
                Streams placeholder replies without loading a model, so you can try the app right away. \
                Nothing is downloaded. Restart the backend after switching.
                """) {
                Toggle("", isOn: $settings.demoMode).labelsHidden()
            }
            LogView(lines: log).frame(height: 100)
        }
    }

    private func choosePython() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.showsHiddenFiles = true
        if panel.runModal() == .OK, let url = panel.url { settings.pythonPath = url.path }
    }
}
