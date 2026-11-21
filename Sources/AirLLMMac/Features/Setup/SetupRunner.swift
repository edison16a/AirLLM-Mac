import Foundation
import Observation

/// Installs everything AirLLM needs into the app's own folder.
///
/// Every step checks what's already there first, so running setup again is quick
/// and works as an updater: it pulls the latest AirLLM and fills in anything missing.
@MainActor
@Observable
final class SetupRunner {
    static let gitURL = "https://github.com/lyogavin/airllm.git"
    static let uvVersion = "0.11.21"

    private(set) var steps = SetupStep.all
    private(set) var log: [String] = []
    private(set) var isRunning = false
    var finished = false
    private(set) var failure: String?
    private(set) var needsCommandLineTools = false

    /// Path to uv once the toolchain step has found or downloaded it.
    var uvPath = ""

    var progress: Double {
        Double(steps.filter(\.isFinished).count) / Double(steps.count)
    }

    func run(settings: AppSettings) {
        guard !isRunning else { return }
        isRunning = true
        failure = nil
        needsCommandLineTools = false
        for i in steps.indices where steps[i].state == .failed { steps[i].state = .pending }
        Task {
            do {
                try await runAllSteps()
                settings.pythonPath = AppPaths.venvPython
                finished = true
            } catch {
                failure = error.localizedDescription
                if let i = steps.firstIndex(where: { $0.state == .running }) { steps[i].state = .failed }
                append(["Failed: \(error.localizedDescription)"])
            }
            isRunning = false
        }
    }

    private func runAllSteps() async throws {
        try await checkMac()
        try await checkGit()
        try await ensureUV()
        try await cloneRepo()
        try await makeVenv()
        try await installPackage(.torch, module: "torch", packages: ["torch"])
        try await installPackage(.mlx, module: "mlx.core", packages: ["mlx"])
        try await installAirLLM()
        try await verify()
        append(["Everything is installed."])
    }

    /// Opens Apple's installer for Git and the other command line tools.
    func installCommandLineTools() {
        Task { _ = try? await command("/usr/bin/xcode-select", ["--install"]) }
    }

    func markNeedsCommandLineTools() { needsCommandLineTools = true }

    // MARK: Helpers for the step implementations

    func set(_ id: SetupStep.ID, _ state: SetupStep.State, _ detail: String? = nil) {
        guard let i = steps.firstIndex(where: { $0.id == id }) else { return }
        steps[i].state = state
        if let detail { steps[i].detail = detail }
    }

    /// Runs a command for a step. Quiet commands are version checks whose output
    /// would only clutter the log.
    @discardableResult
    func command(_ executable: String, _ args: [String], quiet: Bool = false) async throws -> CommandRunner.Result {
        if !quiet { append(["$ \((executable as NSString).lastPathComponent) \(args.joined(separator: " "))"]) }
        let env = CommandRunner.environment(extraBin: AppPaths.bin)
        var forward: (@Sendable ([String]) -> Void)?
        if !quiet {
            forward = { lines in
                Task { @MainActor [weak self] in self?.append(lines) }
            }
        }
        return try await CommandRunner.run(executable, args, environment: env, onLines: forward)
    }

    func append(_ lines: [String]) {
        log.append(contentsOf: lines)
        if log.count > 600 { log.removeFirst(log.count - 600) }
    }
}
