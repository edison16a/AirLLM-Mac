import Foundation

/// Steps that check the Mac and get the tools: Git, uv and the AirLLM source.
extension SetupRunner {
    func checkMac() async throws {
        set(.mac, .running)
        guard SystemInfo.isAppleSilicon else {
            throw AppError("AirLLM's Mac version needs Apple silicon (M1 or later).")
        }
        let info = SystemInfo.current
        guard info.freeDiskGB > 5 else {
            throw AppError("Setup needs about 5 GB of free disk space. You have \(Format.gigabytes(info.freeDiskGB)).")
        }
        let os = ProcessInfo.processInfo.operatingSystemVersion
        set(.mac, .done, "\(info.chipName), macOS \(os.majorVersion).\(os.minorVersion), "
            + "\(Format.gigabytes(info.ramGB)) memory, \(Format.gigabytes(info.freeDiskGB)) free")
    }

    /// /usr/bin/git is only a stub until Apple's Command Line Tools are installed,
    /// so check for the tools first to give a useful message instead of a popup.
    func checkGit() async throws {
        set(.git, .running)
        if try await command("/usr/bin/xcode-select", ["-p"], quiet: true).status != 0 {
            markNeedsCommandLineTools()
            throw AppError("Git comes with Apple's Command Line Tools, which aren't installed. Click Install Tools, finish Apple's installer, then click Retry.")
        }
        let git = try await command("/usr/bin/git", ["--version"], quiet: true)
        guard git.status == 0 else { throw AppError("Git isn't working: \(git.trimmed)") }
        set(.git, .done, git.trimmed)
    }

    /// Uses an existing uv if there is one, otherwise downloads a pinned release from GitHub.
    func ensureUV() async throws {
        set(.uv, .running)
        let candidates = [AppPaths.bin.appendingPathComponent("uv").path,
                          ("~/.local/bin/uv" as NSString).expandingTildeInPath,
                          "/opt/homebrew/bin/uv", "/usr/local/bin/uv"]
        if let found = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            uvPath = found
        } else {
            set(.uv, .running, "Downloading uv \(Self.uvVersion) from GitHub")
            uvPath = try await downloadUV()
        }
        set(.uv, .done, try await command(uvPath, ["--version"], quiet: true).trimmed)
    }

    private func downloadUV() async throws -> String {
        let url = URL(string: "https://github.com/astral-sh/uv/releases/download/\(Self.uvVersion)/uv-aarch64-apple-darwin.tar.gz")!
        append(["Downloading \(url.absoluteString)"])
        let (archive, response) = try await URLSession.shared.download(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw AppError("Couldn't download uv.") }

        let fm = FileManager.default
        let unpack = AppPaths.support.appendingPathComponent("uv-download")
        try? fm.removeItem(at: unpack)
        try fm.createDirectory(at: unpack, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: unpack) }
        guard try await command("/usr/bin/tar", ["-xzf", archive.path, "-C", unpack.path]).status == 0 else {
            throw AppError("Couldn't unpack uv.")
        }
        try fm.createDirectory(at: AppPaths.bin, withIntermediateDirectories: true)
        let destination = AppPaths.bin.appendingPathComponent("uv")
        try? fm.removeItem(at: destination)
        try fm.moveItem(at: unpack.appendingPathComponent("uv-aarch64-apple-darwin/uv"), to: destination)
        return destination.path
    }

    /// Clones AirLLM the first time and pulls on later runs. A failed pull keeps the
    /// existing copy, since being offline shouldn't break an install that works.
    func cloneRepo() async throws {
        set(.clone, .running)
        let repo = AppPaths.repo.path
        if FileManager.default.fileExists(atPath: AppPaths.repo.appendingPathComponent(".git").path) {
            set(.clone, .running, "Updating with git pull")
            if try await command("/usr/bin/git", ["-C", repo, "pull", "--ff-only"]).status != 0 {
                append(["git pull failed, keeping the existing copy"])
            }
        } else {
            try? FileManager.default.removeItem(at: AppPaths.repo)
            let clone = try await command("/usr/bin/git", ["clone", "--depth", "1", "--progress", Self.gitURL, repo])
            guard clone.status == 0 else { throw AppError("git clone failed. Check your internet connection.") }
        }
        let head = try await command("/usr/bin/git", ["-C", repo, "log", "-1", "--format=%h, %cr"], quiet: true)
        set(.clone, .done, "lyogavin/airllm at \(head.trimmed)")
    }
}
