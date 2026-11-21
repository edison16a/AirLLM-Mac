import Foundation
import Observation

/// The list of chats and which one is open. Saves shortly after each change.
@MainActor
@Observable
final class ConversationLibrary {
    var conversations: [Conversation]
    var selection: Conversation.ID?
    private var saveTask: Task<Void, Never>?

    init(conversations: [Conversation] = ConversationStore.load()) {
        self.conversations = conversations.sorted { $0.updated > $1.updated }
        selection = self.conversations.first?.id
        if self.conversations.isEmpty { newConversation() }
    }

    var current: Conversation? { conversations.first { $0.id == selection } }

    func index(of id: Conversation.ID?) -> Int? {
        conversations.firstIndex { $0.id == id }
    }

    /// Reuses an empty chat if there is one, so pressing New Chat twice doesn't pile them up.
    func newConversation() {
        if let empty = conversations.first(where: { $0.messages.isEmpty }) {
            selection = empty.id
            return
        }
        let conversation = Conversation()
        conversations.insert(conversation, at: 0)
        selection = conversation.id
        scheduleSave()
    }

    func delete(_ id: Conversation.ID) {
        conversations.removeAll { $0.id == id }
        if selection == id { selection = conversations.first?.id }
        if conversations.isEmpty { newConversation() }
        scheduleSave()
    }

    func rename(_ id: Conversation.ID, to title: String) {
        guard let i = index(of: id) else { return }
        conversations[i].title = title
        scheduleSave()
    }

    func clear(_ id: Conversation.ID) {
        guard let i = index(of: id) else { return }
        conversations[i].messages.removeAll()
        conversations[i].title = "New Chat"
        scheduleSave()
    }

    func moveToTop(_ id: Conversation.ID) {
        guard let i = index(of: id), i > 0 else { return }
        conversations.insert(conversations.remove(at: i), at: 0)
    }

    func updateMessage(_ convID: Conversation.ID, _ msgID: Message.ID, _ change: (inout Message) -> Void) {
        guard let ci = index(of: convID),
              let mi = conversations[ci].messages.firstIndex(where: { $0.id == msgID }) else { return }
        change(&conversations[ci].messages[mi])
    }

    func search(_ query: String) -> [Conversation] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return conversations }
        return conversations.filter {
            $0.title.localizedCaseInsensitiveContains(q)
                || $0.messages.contains { $0.content.localizedCaseInsensitiveContains(q) }
        }
    }

    /// Debounced so a streaming reply doesn't rewrite the file for every token.
    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, !Task.isCancelled else { return }
            ConversationStore.save(self.conversations)
        }
    }

    func saveNow() { ConversationStore.save(conversations) }
}
