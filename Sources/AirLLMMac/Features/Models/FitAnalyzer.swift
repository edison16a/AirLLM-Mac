import Foundation

enum FitLevel: Int {
    case inMemory, streams, noDisk, noMemory

    var label: String {
        switch self {
        case .inMemory: return "Fits in memory"
        case .streams: return "Streams from disk"
        case .noDisk: return "Not enough disk"
        case .noMemory: return "Not enough memory"
        }
    }

    var canRun: Bool { self == .inMemory || self == .streams }
}

struct FitReport: Equatable {
    var level: FitLevel
    var diskNeededGB: Double
    var downloaded: Bool
    var secondsPerToken: Double
    /// True when the speed comes from real replies on this Mac rather than a guess.
    var calibrated: Bool
    var explanation: String
}

/// The settings and measurements a fit check depends on, passed in as plain values
/// so the analysis is easy to test without touching UserDefaults or the disk.
struct FitInputs {
    var deleteOriginal = false
    var measuredSecondsPerToken: Double?
    var learnedCachedGBps: Double?
    var learnedDiskGBps: Double?
}

/// Decides whether a model can run on this Mac and roughly how fast.
///
/// AirLLM keeps one layer in memory at a time, so memory rarely blocks a model. Disk
/// usually does: the download plus AirLLM's split copy. Speed is mostly how fast the
/// weights can be read for each token, so the estimate is size divided by throughput.
enum FitAnalyzer {
    /// Read throughput in GB/s when the model sits in macOS's file cache, and when it
    /// has to come from the SSD. Replaced by measured numbers after real replies.
    static let defaultCachedGBps = 6.0
    static let defaultDiskGBps = 2.2
    /// Fixed Python and MLX work per layer, on top of reading its weights.
    static let perLayerOverhead = 0.012

    static func analyze(sizeGB: Double, layers: Int, largestShardGB: Double, download: DownloadState,
                        info: SystemInfo, inputs: FitInputs) -> FitReport {
        let needDisk = diskNeeded(sizeGB: sizeGB, largestShardGB: largestShardGB,
                                  download: download, deleteOriginal: inputs.deleteOriginal)
        // One shard, its working copy and the Python, PyTorch and MLX runtime.
        let peakRAM = largestShardGB * 2 + 2.5
        let cached = fitsInCache(sizeGB: sizeGB, ramGB: info.ramGB)

        let level: FitLevel
        if peakRAM > info.ramGB * 0.85 {
            level = .noMemory
        } else if needDisk > info.freeDiskGB - 2 {
            level = .noDisk
        } else {
            level = cached ? .inMemory : .streams
        }
        let speed = secondsPerToken(sizeGB: sizeGB, layers: layers, cached: cached, inputs: inputs)
        return FitReport(level: level, diskNeededGB: needDisk, downloaded: download != .none,
                         secondsPerToken: speed.value, calibrated: speed.measured,
                         explanation: explain(level, sizeGB: sizeGB, needDisk: needDisk, peakRAM: peakRAM,
                                              info: info, deleteOriginal: inputs.deleteOriginal))
    }

    /// macOS needs room for itself and the app, so only count on 60% of memory for cache.
    static func fitsInCache(sizeGB: Double, ramGB: Double) -> Bool { sizeGB < ramGB * 0.6 }

    static func diskNeeded(sizeGB: Double, largestShardGB: Double, download: DownloadState,
                           deleteOriginal: Bool) -> Double {
        switch download {
        case .split: return 0
        case .original: return deleteOriginal ? largestShardGB * 2 : sizeGB * 1.02
        case .none: return deleteOriginal ? sizeGB * 1.1 : sizeGB * 2.05
        }
    }

    static func secondsPerToken(sizeGB: Double, layers: Int, cached: Bool,
                                inputs: FitInputs) -> (value: Double, measured: Bool) {
        if let measured = inputs.measuredSecondsPerToken { return (measured, true) }
        let learned = cached ? inputs.learnedCachedGBps : inputs.learnedDiskGBps
        let gbps = learned ?? (cached ? defaultCachedGBps : defaultDiskGBps)
        return (sizeGB / gbps + Double(layers) * perLayerOverhead, learned != nil)
    }

    private static func explain(_ level: FitLevel, sizeGB: Double, needDisk: Double, peakRAM: Double,
                                info: SystemInfo, deleteOriginal: Bool) -> String {
        let size = Format.gigabytes(sizeGB), ram = Format.gigabytes(info.ramGB)
        switch level {
        case .inMemory:
            return "The whole model (\(size)) fits in this Mac's \(ram) of memory. After the first token macOS keeps it cached, so it runs at its fastest."
        case .streams:
            return "Too big to keep in memory, so AirLLM reads all \(size) from your SSD for every token. It works, but slowly."
        case .noDisk:
            let tip = deleteOriginal ? "" : " Turning on \"Delete original after splitting\" in Advanced settings roughly halves this."
            return "Needs about \(Format.gigabytes(needDisk)) free for the download and AirLLM's layer copy. You have \(Format.gigabytes(info.freeDiskGB)).\(tip)"
        case .noMemory:
            return "Even one layer of this model needs about \(Format.gigabytes(peakRAM)) of memory. This Mac has \(ram)."
        }
    }
}
