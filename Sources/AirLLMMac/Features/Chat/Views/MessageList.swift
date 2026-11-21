import SwiftUI

/// The scrolling list of messages, which sticks to the bottom as a reply streams in.
struct MessageList: View {
    @Environment(AppState.self) private var state
    let conversation: Conversation

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 26) {
                    ForEach(conversation.messages) { message in
                        let isLast = message.id == conversation.messages.last?.id
                        MessageRow(message: message,
                                   isStreaming: isLast && state.chat.generatingConversation == conversation.id,
                                   isLast: isLast)
                            .id(message.id)
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 12)
                .frame(maxWidth: 780)
                .frame(maxWidth: .infinity)
            }
            .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
            .onChange(of: conversation.messages.last?.content) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
            .onChange(of: conversation.id) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
            .onChange(of: conversation.messages.count) { _, _ in
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }
}
