import Foundation

/// Saves chats as one JSON file. Chats are small text, so a single file read at launch
/// and rewritten after changes is simpler than a database and easy to back up.
enum ConversationStore {
    static func load(from url: URL = AppPaths.conversations) -> [Conversation] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Conversation].self, from: data)) ?? []
    }

    static func save(_ conversations: [Conversation], to url: URL = AppPaths.conversations) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(conversations) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
