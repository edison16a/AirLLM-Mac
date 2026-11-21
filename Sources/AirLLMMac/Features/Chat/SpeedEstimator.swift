import Foundation

/// Time estimates for replies, and learning the real speed from finished ones.
///
/// Estimates start from model size (see FitAnalyzer). After a real reply the measured
/// seconds per token replaces the guess, and the implied disk throughput is kept so
/// other models get better guesses too.
@MainActor
enum SpeedEstimator {
    /// Demo mode fakes about this speed.
    static let demoSecondsPerToken = 0.35

    static func secondsPerToken(model: String?, isMock: Bool, settings: AppSettings, info: SystemInfo) -> Double? {
        guard let model else { return nil }
        if isMock { return demoSecondsPerToken }
        if let measured = settings.measuredSecondsPerToken[model] { return measured }
        guard let entry = ModelCatalog.entry(model) else { return nil }
        let cached = FitAnalyzer.fitsInCache(sizeGB: entry.sizeGB, ramGB: info.ramGB)
        return FitAnalyzer.secondsPerToken(sizeGB: entry.sizeGB, layers: entry.layers, cached: cached,
                                           inputs: fitInputs(model: model, settings: settings)).value
    }

    /// The first token also reads the whole prompt, so it costs a bit more than the rest.
    static func replyEstimate(secondsPerToken spt: Double, maxTokens: Int) -> (first: Double, full: Double) {
        (spt * 1.3, spt * (1.3 + Double(maxTokens)))
    }

    /// Upper bound on time left, assuming the reply runs to the token limit.
    /// Uses the speed seen so far in this reply once there are two tokens to measure.
    static func remaining(estimate: Double, generated: Int, maxTokens: Int,
                          firstTokenAt: Date?, layerFraction: Double, now: Date = Date()) -> Double {
        var spt = estimate
        if let first = firstTokenAt, generated > 1 {
            spt = now.timeIntervalSince(first) / Double(generated - 1)
        }
        let tokensLeft = Double(max(maxTokens - generated, 0))
        let promptExtra = generated == 0 ? spt * 0.3 : 0
        return max(0, (tokensLeft - layerFraction) * spt + promptExtra)
    }

    static func fitInputs(model: String, settings: AppSettings) -> FitInputs {
        FitInputs(deleteOriginal: settings.deleteOriginal,
                  measuredSecondsPerToken: settings.measuredSecondsPerToken[model],
                  learnedCachedGBps: settings.learnedCachedGBps,
                  learnedDiskGBps: settings.learnedDiskGBps)
    }

    /// Folds a finished reply into the stored measurements. Averages with the old value
    /// because the first reply after a load is slower (macOS hasn't cached the files yet).
    static func learn(from stats: GenerationStats, model: String, settings: AppSettings, info: SystemInfo) {
        guard let spt = stats.steadySecondsPerToken else { return }
        let old = settings.measuredSecondsPerToken[model]
        settings.measuredSecondsPerToken[model] = old.map { ($0 + spt) / 2 } ?? spt
        guard let entry = ModelCatalog.entry(model) else { return }
        let readSeconds = max(spt - Double(entry.layers) * FitAnalyzer.perLayerOverhead, 0.01)
        let gbps = entry.sizeGB / readSeconds
        if FitAnalyzer.fitsInCache(sizeGB: entry.sizeGB, ramGB: info.ramGB) {
            settings.learnedCachedGBps = gbps
        } else {
            settings.learnedDiskGBps = gbps
        }
    }
}
