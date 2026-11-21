import Foundation

/// Human-friendly numbers for the UI. Kept together so every screen says sizes
/// and times the same way.
enum Format {
    static func gigabytes(_ gb: Double) -> String {
        if gb >= 1000 { return String(format: "%.1f TB", gb / 1000) }
        if gb >= 100 { return String(format: "%.0f GB", gb) }
        return String(format: "%.1f GB", gb)
    }

    static func duration(_ seconds: Double) -> String {
        if seconds < 10 { return String(format: "%.1fs", seconds) }
        if seconds < 60 { return "\(Int(seconds.rounded()))s" }
        let minutes = Int(seconds) / 60, rest = Int(seconds) % 60
        if minutes < 60 { return rest == 0 ? "\(minutes)m" : "\(minutes)m \(rest)s" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }

    /// Fast models read better as tokens per second, slow ones as time per token.
    static func speed(secondsPerToken s: Double) -> String {
        if s < 1 { return String(format: "%.1f tok/s", 1 / s) }
        if s < 60 { return String(format: "%.0f s/token", s) }
        return String(format: "%.1f min/token", s / 60)
    }
}
