import Foundation

/// Turns one NDJSON line from POST /chat into a ChatEvent.
enum ChatEventParser {
    static func parse(_ line: String, startedAt: Date) -> ChatEvent? {
        guard let data = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String else { return nil }
        switch type {
        case "progress":
            return .progress(GenProgress(
                phase: obj["phase"] as? String ?? "token",
                tokenIndex: obj["token_index"] as? Int ?? 0,
                layer: obj["layer"] as? Int ?? 0,
                total: obj["total"] as? Int ?? 0,
                startedAt: startedAt))
        case "token":
            return .token(obj["text"] as? String ?? "")
        case "done":
            return .done(GenerationStats(
                tokens: obj["tokens"] as? Int ?? 0,
                promptTokens: obj["prompt_tokens"] as? Int ?? 0,
                seconds: obj["seconds"] as? Double ?? 0,
                timeToFirstToken: obj["time_to_first_token"] as? Double,
                reason: obj["reason"] as? String ?? ""))
        case "error":
            return .error(obj["message"] as? String ?? "Unknown error")
        default:
            return nil
        }
    }
}
