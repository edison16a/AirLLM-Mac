import SwiftUI

/// Shown under a reply while it's being written: a thin bar for the pass
/// through the model's layers, then the word count, layer, elapsed time and time left.
struct GenerationStatus: View {
    @Environment(AppState.self) private var state
    let hasText: Bool

    var body: some View {
        // Ticks once a second so elapsed time keeps moving between layer updates.
        TimelineView(.periodic(from: .now, by: 1)) { context in
            if let progress = state.chat.progress, progress.total > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    LayerBar(fraction: progress.fraction)
                    Text(details(progress, now: context.date))
                        .monospacedDigit()
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.mini)
                    Text(hasText ? "Writing…" : "Starting…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func details(_ progress: GenProgress, now: Date) -> String {
        let action = progress.phase == "prompt" ? "Reading prompt" : "Writing word \(state.chat.generatedTokens + 1)"
        var parts = [action, "layer \(min(progress.layer + 1, progress.total)) of \(progress.total)"]
        if let start = state.chat.startedAt { parts.append(Format.duration(now.timeIntervalSince(start))) }
        if let left = state.chat.remainingEstimate, left > 1 {
            parts.append("at most \(Format.duration(left)) left")
        }
        return parts.joined(separator: ", ")
    }
}

/// How far the current pass has got through the model.
private struct LayerBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.07))
                Capsule().fill(Color.accentColor.opacity(0.8))
                    .frame(width: max(4, geometry.size.width * fraction))
                    .animation(.linear(duration: 0.15), value: fraction)
            }
        }
        .frame(width: 220, height: 3)
    }
}
