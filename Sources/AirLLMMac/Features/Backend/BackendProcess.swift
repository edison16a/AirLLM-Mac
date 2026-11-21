import Foundation

/// Runs server.py with the Python from setup and forwards its output line by line.
final class BackendProcess {
    private var process: Process?
    private var pipe: Pipe?

    var isRunning: Bool { process?.isRunning ?? false }

    /// Finds server.py. In the built app it's in Resources/backend. When running with
    /// `swift run` there is no bundle, so fall back to the copy in this source tree.
    static func scriptPath() -> String? {
        if let bundled = Bundle.main.path(forResource: "server", ofType: "py", inDirectory: "backend") {
            return bundled
        }
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let dev = repoRoot.appendingPathComponent("backend/server.py").path
        return FileManager.default.fileExists(atPath: dev) ? dev : nil
    }

    /// Starts the server. Throws a message for the user if Python or the script is missing.
    func start(python: String, port: Int, demo: Bool,
               onOutput: @escaping @Sendable ([String]) -> Void,
               onExit: @escaping @Sendable (Int32) -> Void) throws {
        let python = (python as NSString).expandingTildeInPath
        guard FileManager.default.isExecutableFile(atPath: python) else {
            throw AppError("Python wasn't found at \(python). Run setup again or pick it in Settings, Advanced.")
        }
        guard let script = Self.scriptPath() else { throw AppError("server.py is missing from the app.") }

        let p = Process()
        p.executableURL = URL(fileURLWithPath: python)
        // --parent-pid lets the server quit on its own if the app crashes.
        p.arguments = ["-u", script, "--port", "\(port)",
                       "--parent-pid", "\(ProcessInfo.processInfo.processIdentifier)"]
        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        env["TOKENIZERS_PARALLELISM"] = "false"
        env["AIRLLM_CHAT_MOCK"] = demo ? "1" : nil
        p.environment = env

        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let lines = Self.lines(in: handle.availableData)
            if !lines.isEmpty { onOutput(lines) }
        }
        p.terminationHandler = { onExit($0.terminationStatus) }
        try p.run()
        process = p
        self.pipe = pipe
    }

    func stop() {
        pipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminationHandler = nil
        if let p = process, p.isRunning { p.terminate() }
        process = nil
        pipe = nil
    }

    /// Splits raw output into trimmed lines. tqdm redraws with \r, so that counts as a break.
    static func lines(in data: Data) -> [String] {
        guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return [] }
        return s.replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
