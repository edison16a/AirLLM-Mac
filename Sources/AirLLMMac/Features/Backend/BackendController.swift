import Foundation
import Observation

/// Owns the backend's lifecycle and publishes its state to the UI.
///
/// The server is polled instead of pushing updates because loads happen on the
/// server's own thread and can take an hour, and a poll survives server restarts.
@MainActor
@Observable
final class BackendController {
    private(set) var status: BackendStatus = .stopped
    var loadError: String?
    private(set) var log: [String] = []
    private(set) var isMock = false

    private let settings: AppSettings
    private let process = BackendProcess()
    private var pollTask: Task<Void, Never>?

    init(settings: AppSettings) { self.settings = settings }

    var client: BackendClient { BackendClient(baseURL: URL(string: "http://127.0.0.1:\(settings.port)")!) }
    var modelID: String? { status.modelID }
    var isReady: Bool { modelID != nil }

    func start() {
        guard !process.isRunning else { return }
        status = .starting
        Task {
            // A server left over from an earlier launch is reused rather than fought with.
            if await client.health() == nil { launch() }
            if case .failed = status { return }
            startPolling()
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        status = .stopped
        process.stop()
    }

    func restart() {
        stop()
        log.removeAll()
        Task {
            try? await Task.sleep(for: .milliseconds(600))  // let the port free up
            start()
        }
    }

    func load(_ model: String, hfToken: String?) async {
        var body: [String: Any] = ["model": model]
        if let t = hfToken, !t.isEmpty { body["hf_token"] = t }
        if !settings.layerShardsPath.isEmpty { body["layer_shards_saving_path"] = settings.layerShardsPath }
        if settings.deleteOriginal { body["delete_original"] = true }
        if settings.showMemoryUtil { body["show_memory_util"] = true }
        loadError = nil
        if let problem = await client.load(body) {
            loadError = problem
        } else {
            status = .loading(model: model)
        }
    }

    func unload() async { await client.unload() }
    func stopGeneration() { Task { await client.stop() } }

    private func launch() {
        do {
            try process.start(
                python: settings.pythonPath, port: settings.port, demo: settings.demoMode,
                onOutput: { lines in Task { @MainActor [weak self] in self?.append(lines) } },
                onExit: { code in Task { @MainActor [weak self] in self?.processExited(code) } })
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func processExited(_ code: Int32) {
        if case .stopped = status { return }
        status = .failed("The AirLLM backend quit unexpectedly (code \(code)). The log in Settings shows why.")
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            var misses = 0
            while !Task.isCancelled {
                guard let self else { return }
                if let health = await self.client.health() {
                    misses = 0
                    self.apply(health)
                } else if case .starting = self.status {
                    misses += 1
                    // Importing PyTorch and MLX takes a while on first run, so allow ~40s.
                    if misses > 60 { self.status = .failed("The backend didn't start in time. The log in Settings shows why.") }
                }
                try? await Task.sleep(for: .milliseconds(700))
            }
        }
    }

    private func apply(_ health: BackendHealth) {
        isMock = health.mock ?? false
        if !process.isRunning, let lines = health.log { log = lines }  // attached to a server we didn't start
        if case .failed = status { return }
        status = health.status
        if health.error != loadError { loadError = health.error }
    }

    private func append(_ lines: [String]) {
        log.append(contentsOf: lines)
        if log.count > 400 { log.removeFirst(log.count - 400) }
    }
}
