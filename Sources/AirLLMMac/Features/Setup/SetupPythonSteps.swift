import Foundation

/// Steps that build the Python environment and install AirLLM into it.
extension SetupRunner {
    func makeVenv() async throws {
        set(.venv, .running)
        if !FileManager.default.isExecutableFile(atPath: AppPaths.venvPython) {
            // uv downloads a standalone Python 3.12 if the Mac doesn't have one.
            let result = try await command(uvPath, ["venv", "--python", "3.12", AppPaths.venv.path])
            guard result.status == 0 else { throw AppError("Couldn't create the Python environment.") }
        }
        set(.venv, .done, try await command(AppPaths.venvPython, ["--version"], quiet: true).trimmed)
    }

    /// Installs a package unless it already imports, which keeps re-runs fast.
    func installPackage(_ id: SetupStep.ID, module: String, packages: [String]) async throws {
        set(id, .running)
        if let version = await installedVersion(module) {
            set(id, .skipped, "Already installed, version \(version)")
            return
        }
        set(id, .running, "Downloading and installing")
        let result = try await command(uvPath, ["pip", "install", "--python", AppPaths.venvPython] + packages)
        guard result.status == 0 else {
            throw AppError("Installing \(packages.joined(separator: " and ")) failed. Details has the full output.")
        }
        set(id, .done, "Installed version \(await installedVersion(module) ?? "unknown")")
    }

    /// Editable install from the clone, so a later git pull updates AirLLM without reinstalling.
    func installAirLLM() async throws {
        set(.airllm, .running, "pip install -e air_llm")
        let source = AppPaths.repo.appendingPathComponent("air_llm").path
        let result = try await command(uvPath, ["pip", "install", "--python", AppPaths.venvPython, "-e", source])
        guard result.status == 0 else { throw AppError("Installing AirLLM failed. Details has the full output.") }
        set(.airllm, .done, "Installed version \(await installedVersion("airllm") ?? "unknown")")
    }

    func verify() async throws {
        set(.verify, .running)
        let script = """
        import warnings; warnings.filterwarnings("ignore")
        import torch, mlx.core, importlib.metadata as md
        from airllm import AutoModel
        gpu = "on" if torch.backends.mps.is_available() else "off"
        print("OK|airllm %s, torch %s, mlx %s, Metal %s" % (md.version("airllm"), torch.__version__, md.version("mlx"), gpu))
        """
        let result = try await command(AppPaths.venvPython, ["-c", script])
        guard result.status == 0,
              let line = result.output.split(separator: "\n").last(where: { $0.hasPrefix("OK|") }) else {
            throw AppError("AirLLM didn't import correctly. Details has the error.")
        }
        set(.verify, .done, String(line.dropFirst(3)))
    }

    private func installedVersion(_ module: String) async -> String? {
        let distribution = module.split(separator: ".")[0]
        let script = "import \(module), importlib.metadata as md; print(md.version('\(distribution)'))"
        guard let result = try? await command(AppPaths.venvPython, ["-c", script], quiet: true),
              result.status == 0 else { return nil }
        return result.trimmed.split(separator: "\n").last.map(String.init)
    }
}
