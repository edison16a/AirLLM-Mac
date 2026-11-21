import Foundation

/// One row in the setup checklist.
struct SetupStep: Identifiable, Equatable {
    enum State: Equatable { case pending, running, done, skipped, failed }

    enum ID: String {
        case mac, git, uv, clone, venv, torch, mlx, airllm, verify
    }

    let id: ID
    let title: String
    var detail: String
    var state: State = .pending

    var isFinished: Bool { state == .done || state == .skipped }

    /// The full install, in order. Each later step depends on the ones before it.
    static let all: [SetupStep] = [
        .init(id: .mac, title: "Check this Mac", detail: "Apple silicon, macOS, memory and disk"),
        .init(id: .git, title: "Git", detail: "Needed to download AirLLM from GitHub"),
        .init(id: .uv, title: "Python toolchain", detail: "uv, a fast Python installer"),
        .init(id: .clone, title: "Download AirLLM", detail: "git clone github.com/lyogavin/airllm"),
        .init(id: .venv, title: "Python environment", detail: "Python 3.12, private to this app"),
        .init(id: .torch, title: "PyTorch", detail: "About 300 MB"),
        .init(id: .mlx, title: "MLX", detail: "Apple's framework for running models on the GPU"),
        .init(id: .airllm, title: "AirLLM", detail: "Installed from the downloaded source"),
        .init(id: .verify, title: "Verify", detail: "Import everything and check the GPU"),
    ]
}
