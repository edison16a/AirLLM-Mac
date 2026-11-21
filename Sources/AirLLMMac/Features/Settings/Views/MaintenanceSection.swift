import SwiftUI

/// Advanced: restart the backend, reset estimates, run setup again and restore defaults.
struct MaintenanceSection: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Section("Maintenance") {
            ActionRow("Restart Backend", info: """
                Stops and starts the AirLLM server. You need this after changing Python, Port or Demo mode. \
                It unloads the current model, which reloads by itself if Load last model on launch is on.
                """) { state.backend.restart() }
            ActionRow("Reset Speed Estimates", info: """
                Time estimates start as guesses from model size, then switch to the real speed measured \
                from your replies. Reset them after changing drives or getting a new Mac.
                """) { state.settings.resetCalibration() }
            ActionRow("Run Setup Again…", info: """
                Checks and updates everything. It pulls the latest AirLLM from GitHub and installs anything \
                missing. Packages that are already installed are kept.
                """) { state.rerunSetup() }
            ActionRow("Restore Default Reply Settings") { state.settings.resetReplyDefaults() }
        }
    }
}
