import Foundation

enum Role: String, Codable {
    case user, assistant, system
}

/// One chat message. Assistant replies also carry the model that wrote them and how long
/// it took, so old chats keep the right logo and stats after you switch models.
struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: Role
    var content: String
    var date = Date()
    var stats: GenerationStats?
    var error: String?
    var modelID: String?
}
