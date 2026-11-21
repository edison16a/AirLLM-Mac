import SwiftUI

@main
struct AirLLMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup("AirLLM") {
            RootView()
                .environment(state)
                .onAppear(perform: launch)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1040, height: 720)
        .commands { AppCommands(state: state) }

        Settings {
            SettingsView().environment(state)
        }
    }

    private func launch() {
        delegate.onTerminate = { [state] in
            MainActor.assumeIsolated { state.shutdown() }
        }
        state.startIfReady()
        // Starts setup without clicking Install. Used to test setup from the command line.
        if CommandLine.arguments.contains("--auto-setup"), state.needsSetup {
            state.setup.run(settings: state.settings)
        }
    }
}
