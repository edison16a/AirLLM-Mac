import SwiftUI

/// Shows setup until AirLLM is installed, then the chat window.
struct RootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if state.needsSetup {
                SetupView()
            } else {
                MainWindow()
            }
        }
        .frame(minWidth: 760, minHeight: 560)
        .animation(.easeInOut(duration: 0.25), value: state.needsSetup)
    }
}

/// The chat list beside the open chat, with the model picker as a sheet.
struct MainWindow: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var state = state
        NavigationSplitView {
            SidebarView()
        } detail: {
            ChatView()
                .toolbar {
                    ToolbarItem(placement: .navigation) { ModelPickerButton() }
                }
        }
        .sheet(isPresented: $state.showModelPicker) {
            ModelPicker().environment(state)
        }
        .onChange(of: state.backend.status) { _, _ in state.backendStatusChanged() }
    }
}
