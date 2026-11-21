import Foundation

/// Every folder the app writes to, in one place.
enum AppPaths {
    /// ~/Library/Application Support/AirLLM Chat. The name predates the AirLLM rename and
    /// is kept so existing installs keep their environment and chats.
    static var support: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("AirLLM Chat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var conversations: URL { support.appendingPathComponent("conversations.json") }
    static var repo: URL { support.appendingPathComponent("airllm") }
    static var venv: URL { support.appendingPathComponent("venv") }
    static var venvPython: String { venv.appendingPathComponent("bin/python").path }
    static var bin: URL { support.appendingPathComponent("bin") }

    /// Where huggingface_hub keeps downloads unless HF_HOME says otherwise.
    static var huggingFaceHub: URL {
        if let home = ProcessInfo.processInfo.environment["HF_HOME"] {
            return URL(fileURLWithPath: home).appendingPathComponent("hub")
        }
        return URL(fileURLWithPath: ("~/.cache/huggingface/hub" as NSString).expandingTildeInPath)
    }
}
