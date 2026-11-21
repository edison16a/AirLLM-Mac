import Foundation

/// What the backend reports when a reply finishes.
struct GenerationStats: Codable, Equatable {
    var tokens: Int
    var promptTokens: Int
    var seconds: Double
    var timeToFirstToken: Double?
    /// "eos" (model finished), "length" (hit the token limit) or "stopped" (user pressed Stop).
    var reason: String

    /// Seconds per generated token, leaving out the prompt pass. Nil when there are too few
    /// tokens to measure, since the first token also includes reading the prompt.
    var steadySecondsPerToken: Double? {
        guard tokens >= 3, let ttft = timeToFirstToken else { return nil }
        let spt = (seconds - ttft) / Double(tokens - 1)
        return spt > 0 ? spt : nil
    }
}

/// Where AirLLM is in the model right now. Each token is a full pass over every layer,
/// so this is the only honest progress signal while a slow model is working.
struct GenProgress: Equatable {
    var phase: String  // "prompt" while reading the prompt, "token" afterwards
    var tokenIndex: Int
    var layer: Int
    var total: Int
    var startedAt: Date

    var fraction: Double { total > 0 ? Double(layer) / Double(total) : 0 }
}

/// Events streamed from the backend while a reply is generated.
enum ChatEvent {
    case progress(GenProgress)
    case token(String)
    case done(GenerationStats)
    case error(String)
}
