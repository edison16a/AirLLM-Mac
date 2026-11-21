import Foundation

/// Runs a command, streams its output lines, and returns its exit code and full output.
enum CommandRunner {
    struct Result {
        var status: Int32
        var output: String
        var trimmed: String { output.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    /// Apps launched from Finder get a bare PATH, so add the usual tool locations.
    static func environment(extraBin: URL) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "\(extraBin.path):/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["GIT_TERMINAL_PROMPT"] = "0"  // fail instead of waiting for a password nobody can type
        env["NO_COLOR"] = "1"
        return env
    }

    static func run(_ executable: String, _ args: [String], environment: [String: String],
                    onLines: (@Sendable ([String]) -> Void)? = nil) async throws -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.environment = environment
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let collected = OutputBuffer()
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return }
            collected.append(s)
            onLines?(BackendProcess.lines(in: data))
        }
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { p in
                pipe.fileHandleForReading.readabilityHandler = nil
                let rest = pipe.fileHandleForReading.readDataToEndOfFile()
                if let s = String(data: rest, encoding: .utf8) { collected.append(s) }
                continuation.resume(returning: Result(status: p.terminationStatus, output: collected.value))
            }
            do { try process.run() } catch { continuation.resume(throwing: error) }
        }
    }
}

/// Collects output from the pipe's background thread.
final class OutputBuffer: @unchecked Sendable {
    private var text = ""
    private let lock = NSLock()

    func append(_ s: String) {
        lock.lock()
        text += s
        lock.unlock()
    }

    var value: String {
        lock.lock()
        defer { lock.unlock() }
        return text
    }
}
