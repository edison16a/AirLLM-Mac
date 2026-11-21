import SwiftUI

/// The detail pane: the open conversation, or the welcome view when it's empty.
struct ChatView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        Group {
            if let conversation = state.library.current, !conversation.messages.isEmpty {
                VStack(spacing: 0) {
                    MessageList(conversation: conversation)
                    Composer().padding(.bottom, 16)
                }
            } else {
                EmptyChatView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
