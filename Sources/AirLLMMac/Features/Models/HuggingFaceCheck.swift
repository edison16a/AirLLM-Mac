import Foundation

/// What the Hugging Face API says about a repo, reduced to what the fit check needs.
struct HuggingFaceModelInfo: Equatable {
    var repo: String
    var architecture: String
    var tiedEmbeddings: Bool
    var sizeGB: Double
    var layers: Int
    var vocab: Int
    var hidden: Int
    var gated: Bool

    /// Architectures AirLLM's MLX code path can load on macOS.
    static let supportedArchitectures: Set<String> = ["LlamaForCausalLM", "MistralForCausalLM"]

    var supported: Bool { Self.supportedArchitectures.contains(architecture) && !tiedEmbeddings }

    var asCatalogModel: CatalogModel {
        CatalogModel(repo: repo, name: ModelCatalog.displayName(repo), params: "",
                     provider: ModelCatalog.logo(for: repo), sizeGB: sizeGB, layers: max(layers, 1),
                     vocab: vocab, hidden: hidden, gated: gated,
                     blurb: supported ? "\(architecture), \(layers) layers"
                                      : "\(architecture)\(tiedEmbeddings ? " with tied embeddings" : "") isn't supported by AirLLM on macOS.")
    }

    /// Builds the summary from the model API response and the repo's config.json.
    /// Falls back to estimating the parameter count from the layer shapes when the Hub
    /// has no safetensors metadata (older pytorch_model.bin repos).
    static func parse(repo: String, info: [String: Any], config: [String: Any]) -> HuggingFaceModelInfo {
        let layers = config["num_hidden_layers"] as? Int ?? 0
        let vocab = config["vocab_size"] as? Int ?? 32_000
        let hidden = config["hidden_size"] as? Int ?? 4096
        var params = Double((info["safetensors"] as? [String: Any])?["total"] as? Int ?? 0)
        if params == 0 {
            let inter = Double(config["intermediate_size"] as? Int ?? hidden * 4)
            let perLayer = 4 * Double(hidden * hidden) + 3 * Double(hidden) * inter
            params = Double(layers) * perLayer + 2 * Double(vocab * hidden)
        }
        // "gated" is false, or a string like "auto" or "manual" when access must be requested.
        let gated: Bool
        if let s = info["gated"] as? String { gated = s != "false" } else { gated = info["gated"] as? Bool ?? false }
        return HuggingFaceModelInfo(
            repo: repo,
            architecture: (config["architectures"] as? [String])?.first ?? "unknown",
            tiedEmbeddings: config["tie_word_embeddings"] as? Bool ?? false,
            sizeGB: params * 2 / 1e9, layers: layers, vocab: vocab, hidden: hidden, gated: gated)
    }
}

enum HuggingFaceCheck {
    static func fetch(_ repo: String, token: String?) async throws -> HuggingFaceModelInfo {
        let info = try await getJSON("https://huggingface.co/api/models/\(repo)", repo: repo, token: token)
        let config = try await getJSON("https://huggingface.co/\(repo)/resolve/main/config.json", repo: repo, token: token)
        return HuggingFaceModelInfo.parse(repo: repo, info: info, config: config)
    }

    private static func getJSON(_ url: String, repo: String, token: String?) async throws -> [String: Any] {
        guard let u = URL(string: url) else { throw AppError("\"\(repo)\" isn't a valid repo id.") }
        var request = URLRequest(url: u)
        request.timeoutInterval = 20
        if let t = token, !t.isEmpty { request.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await URLSession.shared.data(for: request)
        switch (response as? HTTPURLResponse)?.statusCode ?? 0 {
        case 200: break
        case 401, 403: throw AppError("This model is gated. Add a Hugging Face token and accept its license first.")
        case 404: throw AppError("There's no model called \(repo) on Hugging Face.")
        case let code: throw AppError("Hugging Face returned an error (\(code)).")
        }
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError("Hugging Face sent back something unexpected.")
        }
        return obj
    }
}
