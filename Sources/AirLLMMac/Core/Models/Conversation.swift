import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String = "New Chat"
    var messages: [Message] = []
    var created = Date()
    var updated = Date()
    var modelID: String?

    /// Sidebar title from the first line of the first message, cut short so it fits.
    static func title(from text: String) -> String {
        let firstLine = text.split(separator: "\n").first.map(String.init) ?? text
        return firstLine.count > 48 ? String(firstLine.prefix(45)) + "…" : firstLine
    }
}
