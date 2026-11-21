import Foundation

/// How much of a model is already on disk. This changes how much free space a load needs.
enum DownloadState {
    case none
    /// The Hugging Face download exists but AirLLM hasn't split it into layers yet.
    case original
    /// AirLLM's per-layer copy exists, so loading needs no new disk space.
    case split
}

enum ModelDownloads {
    static func state(of repo: String, shardsPath: String) -> DownloadState {
        if repo.hasPrefix("/") {
            let split = URL(fileURLWithPath: repo).appendingPathComponent("splitted_model")
            return FileManager.default.fileExists(atPath: split.path) ? .split : .original
        }
        let dir = AppPaths.huggingFaceHub
            .appendingPathComponent("models--" + repo.replacingOccurrences(of: "/", with: "--"))
            .appendingPathComponent("snapshots")
        guard let snapshots = try? FileManager.default.contentsOfDirectory(atPath: dir.path),
              !snapshots.isEmpty else { return .none }
        if hasCustomSplit(repo: repo, shardsPath: shardsPath) { return .split }
        // AirLLM writes "splitted_model" next to the weights inside the snapshot folder.
        for s in snapshots {
            let split = dir.appendingPathComponent(s).appendingPathComponent("splitted_model")
            if FileManager.default.fileExists(atPath: split.path) { return .split }
        }
        return .original
    }

    /// With a custom split folder AirLLM names subfolders after the model, so a match
    /// on the model's name is the best signal available without parsing its layout.
    private static func hasCustomSplit(repo: String, shardsPath: String) -> Bool {
        guard !shardsPath.isEmpty, let name = repo.split(separator: "/").last else { return false }
        let folder = (shardsPath as NSString).expandingTildeInPath
        let items = (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
        return items.contains { $0.contains(name) }
    }
}
