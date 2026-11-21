import Foundation
import Observation

/// User preferences, saved to UserDefaults as they change.
///
/// The speed fields are not preferences. They hold measurements from real replies,
/// which turn the size-based time estimates into numbers measured on this Mac.
@MainActor
@Observable
final class AppSettings {
    private let defaults: UserDefaults

    // Replies
    var maxNewTokens: Int { didSet { defaults.set(maxNewTokens, forKey: Key.maxNewTokens) } }
    var temperature: Double { didSet { defaults.set(temperature, forKey: Key.temperature) } }
    var systemPrompt: String { didSet { defaults.set(systemPrompt, forKey: Key.systemPrompt) } }
    var autoLoadLastModel: Bool { didSet { defaults.set(autoLoadLastModel, forKey: Key.autoLoad) } }

    // Advanced
    var advancedMode: Bool { didSet { defaults.set(advancedMode, forKey: Key.advancedMode) } }
    var historyTurns: Int { didSet { defaults.set(historyTurns, forKey: Key.historyTurns) } }
    var layerShardsPath: String { didSet { defaults.set(layerShardsPath, forKey: Key.shardsPath) } }
    var deleteOriginal: Bool { didSet { defaults.set(deleteOriginal, forKey: Key.deleteOriginal) } }
    var showMemoryUtil: Bool { didSet { defaults.set(showMemoryUtil, forKey: Key.showMemory) } }
    var pythonPath: String { didSet { defaults.set(pythonPath, forKey: Key.pythonPath) } }
    var port: Int { didSet { defaults.set(port, forKey: Key.port) } }
    var demoMode: Bool { didSet { defaults.set(demoMode, forKey: Key.demoMode) } }

    // App state
    var setupComplete: Bool { didSet { defaults.set(setupComplete, forKey: Key.setupComplete) } }
    var lastModel: String { didSet { defaults.set(lastModel, forKey: Key.lastModel) } }

    // Measured speed
    var measuredSecondsPerToken: [String: Double] { didSet { defaults.set(measuredSecondsPerToken, forKey: Key.measured) } }
    var learnedCachedGBps: Double? { didSet { defaults.set(learnedCachedGBps, forKey: Key.cachedGBps) } }
    var learnedDiskGBps: Double? { didSet { defaults.set(learnedDiskGBps, forKey: Key.diskGBps) } }

    static let defaultSystemPrompt = "You are a helpful assistant."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        maxNewTokens = defaults.object(forKey: Key.maxNewTokens) as? Int ?? 256
        temperature = defaults.object(forKey: Key.temperature) as? Double ?? 0
        systemPrompt = defaults.string(forKey: Key.systemPrompt) ?? Self.defaultSystemPrompt
        autoLoadLastModel = defaults.object(forKey: Key.autoLoad) as? Bool ?? true
        advancedMode = defaults.bool(forKey: Key.advancedMode)
        historyTurns = defaults.object(forKey: Key.historyTurns) as? Int ?? 6
        layerShardsPath = defaults.string(forKey: Key.shardsPath) ?? ""
        deleteOriginal = defaults.bool(forKey: Key.deleteOriginal)
        showMemoryUtil = defaults.bool(forKey: Key.showMemory)
        pythonPath = defaults.string(forKey: Key.pythonPath) ?? AppPaths.venvPython
        port = defaults.object(forKey: Key.port) as? Int ?? 8765
        demoMode = defaults.bool(forKey: Key.demoMode)
        setupComplete = defaults.bool(forKey: Key.setupComplete)
        lastModel = defaults.string(forKey: Key.lastModel) ?? ""
        measuredSecondsPerToken = defaults.dictionary(forKey: Key.measured) as? [String: Double] ?? [:]
        learnedCachedGBps = defaults.object(forKey: Key.cachedGBps) as? Double
        learnedDiskGBps = defaults.object(forKey: Key.diskGBps) as? Double
    }

    func resetCalibration() {
        measuredSecondsPerToken = [:]
        learnedCachedGBps = nil
        learnedDiskGBps = nil
    }

    func resetReplyDefaults() {
        maxNewTokens = 256
        temperature = 0
        systemPrompt = Self.defaultSystemPrompt
        historyTurns = 6
    }

    /// Key names are shared with earlier builds so upgrading keeps everyone's settings.
    private enum Key {
        static let maxNewTokens = "maxNewTokens", temperature = "temperature"
        static let systemPrompt = "systemPrompt", autoLoad = "autoLoadLastModel"
        static let advancedMode = "advancedMode", historyTurns = "historyTurns"
        static let shardsPath = "layerShardsPath", deleteOriginal = "deleteOriginal"
        static let showMemory = "showMemoryUtil", pythonPath = "pythonPath"
        static let port = "port", demoMode = "demoMode"
        static let setupComplete = "setupComplete", lastModel = "lastModel"
        static let measured = "measuredSPT", cachedGBps = "learnedCachedGBps", diskGBps = "learnedDiskGBps"
    }
}
