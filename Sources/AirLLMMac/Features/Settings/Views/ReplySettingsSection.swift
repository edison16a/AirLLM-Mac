import SwiftUI

/// The settings everyone sees: reply length, creativity, auto-load and instructions.
struct ReplySettingsSection: View {
    @Bindable var settings: AppSettings

    var body: some View {
        Section("Replies") {
            SettingRow("Max reply length", info: """
                The most tokens a reply can have. A token is roughly three quarters of a word. \
                AirLLM reads the whole model from disk for every token, so this is the biggest factor \
                in how long a reply can take. Replies usually stop earlier on their own.
                """) {
                HStack(spacing: 6) {
                    TextField("", value: $settings.maxNewTokens, format: .number)
                        .frame(width: 64)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $settings.maxNewTokens, in: 1...8192, step: 32).labelsHidden()
                    Text("tokens").foregroundStyle(.secondary)
                }
            }
            SettingRow("Creativity", info: """
                This is the temperature. At 0 the model always picks its most likely next word, \
                so the same question gets the same answer. Higher values pick more varied words, which is \
                more creative but more likely to drift. Use 0.6 to 0.8 for writing and 0 for facts and code.
                """) {
                HStack {
                    Slider(value: $settings.temperature, in: 0...1.5, step: 0.05).frame(width: 170)
                    Text(settings.temperature == 0 ? "Precise" : String(format: "%.2f", settings.temperature))
                        .monospacedDigit()
                        .frame(width: 54, alignment: .trailing)
                }
            }
            SettingRow("Load last model on launch", info: """
                Reloads the model you used last time when the app opens, so you can start typing right away. \
                A model that's already downloaded loads in a few seconds.
                """) {
                Toggle("", isOn: $settings.autoLoadLastModel).labelsHidden()
            }
            instructions
        }
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Instructions")
                InfoButton("""
                    The system prompt. These are hidden instructions sent at the start of every chat, \
                    like "Answer briefly" or "You are a Python expert." Shorter instructions make replies start a bit sooner.
                    """)
            }
            TextEditor(text: $settings.systemPrompt)
                .font(.body)
                .frame(height: 70)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}
