import Foundation

/// Models offered in the picker.
///
/// On macOS AirLLM only runs Llama and Mistral architectures with separate output
/// weights, so the list sticks to those. Tied-embedding models like Llama 3.2 1B/3B
/// are left out on purpose: AirLLM's splitter expects an lm_head file they don't have.
enum ModelCatalog {
    static let all: [CatalogModel] = [
        .init(repo: "TinyLlama/TinyLlama-1.1B-Chat-v1.0", name: "TinyLlama", params: "1.1B",
              provider: "huggingface-color", sizeGB: 2.2, layers: 22, vocab: 32_000, hidden: 2048,
              blurb: "Tiny and quick. Best for trying things out."),
        .init(repo: "NousResearch/Meta-Llama-3.1-8B-Instruct", name: "Llama 3.1 Instruct", params: "8B",
              provider: "meta-color", sizeGB: 16.1, layers: 32,
              blurb: "Meta's well-rounded assistant."),
        .init(repo: "deepseek-ai/DeepSeek-R1-Distill-Llama-8B", name: "DeepSeek R1 Distill", params: "8B",
              provider: "deepseek-color", sizeGB: 16.1, layers: 32,
              blurb: "Thinks step by step before answering, so replies run long."),
        .init(repo: "NousResearch/Hermes-3-Llama-3.1-8B", name: "Hermes 3", params: "8B",
              provider: "nousresearch", sizeGB: 16.1, layers: 32,
              blurb: "Nous Research's tune of Llama 3.1. Follows instructions closely."),
        .init(repo: "mistralai/Mistral-7B-Instruct-v0.3", name: "Mistral Instruct v0.3", params: "7B",
              provider: "mistral-color", sizeGB: 14.5, layers: 32, vocab: 32_768, gated: true,
              blurb: "Fast, capable 7B. Accept the license on Hugging Face first."),
        .init(repo: "01-ai/Yi-1.5-9B-Chat", name: "Yi 1.5 Chat", params: "9B",
              provider: "yi-color", sizeGB: 17.7, layers: 48, vocab: 64_000,
              blurb: "01.AI's bilingual English and Chinese model."),
        .init(repo: "deepseek-ai/DeepSeek-R1-Distill-Llama-70B", name: "DeepSeek R1 Distill", params: "70B",
              provider: "deepseek-color", sizeGB: 141, layers: 80, hidden: 8192,
              blurb: "Strong reasoning. Expect minutes per token from disk."),
        .init(repo: "NousResearch/Hermes-3-Llama-3.1-70B", name: "Hermes 3", params: "70B",
              provider: "nousresearch", sizeGB: 141, layers: 80, hidden: 8192,
              blurb: "Large and capable. This is what AirLLM is built for."),
        .init(repo: "meta-llama/Llama-3.3-70B-Instruct", name: "Llama 3.3 Instruct", params: "70B",
              provider: "meta-color", sizeGB: 141, layers: 80, hidden: 8192, gated: true,
              blurb: "Meta's best 70B. Needs a Hugging Face token."),
        .init(repo: "meta-llama/Llama-3.1-405B-Instruct", name: "Llama 3.1 Instruct", params: "405B",
              provider: "meta-color", sizeGB: 812, layers: 126, hidden: 16384, gated: true,
              blurb: "The giant. Needs nearly 2 TB of free disk."),
    ]

    static func entry(_ repo: String?) -> CatalogModel? {
        guard let repo else { return nil }
        return all.first { $0.repo == repo }
    }

    /// Picks a logo for any repo id: the catalog entry when there is one, otherwise a
    /// guess from the name so custom models still get a recognizable icon.
    static func logo(for repo: String?) -> String {
        if let m = entry(repo) { return m.provider }
        let r = (repo ?? "").lowercased()
        if r.contains("deepseek") { return "deepseek-color" }
        if r.contains("mistral") { return "mistral-color" }
        if r.contains("hermes") || r.contains("nous") { return "nousresearch" }
        if r.contains("yi-") || r.hasPrefix("01-ai") { return "yi-color" }
        if r.contains("llama") { return "meta-color" }
        return "huggingface-color"
    }

    /// Short name for a repo id or local folder, used in the toolbar and placeholders.
    static func displayName(_ repo: String) -> String {
        if let m = entry(repo) { return m.displayName }
        if repo.hasPrefix("/") { return (repo as NSString).lastPathComponent }
        return repo.split(separator: "/").last.map(String.init) ?? repo
    }
}
