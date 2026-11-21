import SwiftUI

/// The File and Model menus, with their keyboard shortcuts.
struct AppCommands: Commands {
    let state: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Chat") { state.library.newConversation() }
                .keyboardShortcut("n")
                .disabled(state.needsSetup)
        }
        CommandMenu("Model") {
            Button("Choose Model…") { state.showModelPicker = true }
                .keyboardShortcut("m", modifiers: [.command, .shift])
                .disabled(state.needsSetup)
            Button("Stop Generating") { state.chat.stop() }
                .keyboardShortcut(".")
                .disabled(!state.chat.isGenerating)
            Button("Regenerate Reply") { state.chat.regenerate() }
                .keyboardShortcut("r")
                .disabled(state.chat.isGenerating || !state.backend.isReady)
            Divider()
            Button("Restart Backend") { state.backend.restart() }
                .disabled(state.needsSetup)
            Button("Run Setup Again…") { state.rerunSetup() }
        }
    }
}
