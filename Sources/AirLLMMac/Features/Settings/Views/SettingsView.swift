import SwiftUI

/// The Settings window. Simple mode shows the reply settings. Advanced adds
/// storage, the backend and maintenance. Every setting has an info button.
struct SettingsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var settings = state.settings
        VStack(spacing: 0) {
            Picker("", selection: $settings.advancedMode) {
                Text("Simple").tag(false)
                Text("Advanced").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)
            .padding(.top, 14)
            .padding(.bottom, 4)

            Form {
                ReplySettingsSection(settings: settings)
                if settings.advancedMode {
                    StorageSettingsSection(settings: settings)
                    BackendSettingsSection(settings: settings, log: state.backend.log)
                    MaintenanceSection()
                } else {
                    Section {
                        Text("Switch to Advanced for storage, speed estimates, the Python environment and backend options.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 560, height: settings.advancedMode ? 720 : 470)
        .animation(.easeInOut(duration: 0.2), value: settings.advancedMode)
    }
}
