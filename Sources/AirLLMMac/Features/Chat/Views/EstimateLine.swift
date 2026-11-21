import SwiftUI

/// The line under the message box that says how long a reply will take.
struct EstimateLine: View {
    @Environment(AppState.self) private var state

    var body: some View {
        HStack(spacing: 5) {
            if state.chat.isGenerating {
                if let left = state.chat.remainingEstimate {
                    Image(systemName: "clock")
                    Text("At most \(Format.duration(left)) left. Press ⌘. to stop.")
                }
            } else if let estimate = state.chat.replyEstimate {
                Image(systemName: "clock")
                Text("First words in about \(Format.duration(estimate.first)), "
                     + "a full \(state.settings.maxNewTokens)-token reply in about \(Format.duration(estimate.full))")
                if isUnmeasured {
                    InfoButton("This is a guess from the model's size and your Mac's memory. "
                               + "After the first reply the app measures the real speed and uses that instead.")
                }
            } else {
                Text(" ")
            }
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
        .animation(.default, value: state.chat.isGenerating)
    }

    private var isUnmeasured: Bool {
        guard let model = state.backend.modelID, !state.backend.isMock else { return false }
        return state.settings.measuredSecondsPerToken[model] == nil
    }
}
