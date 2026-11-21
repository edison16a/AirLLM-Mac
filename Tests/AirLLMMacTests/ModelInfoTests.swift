import XCTest
@testable import AirLLMMac

final class ModelInfoTests: XCTestCase {
    func testParseUsesSafetensorsCount() {
        let info = HuggingFaceModelInfo.parse(
            repo: "org/llama",
            info: ["safetensors": ["total": 8_000_000_000], "gated": "manual"],
            config: ["architectures": ["LlamaForCausalLM"], "num_hidden_layers": 32,
                     "vocab_size": 128_256, "hidden_size": 4096])
        XCTAssertEqual(info.sizeGB, 16, accuracy: 0.001)
        XCTAssertTrue(info.gated)
        XCTAssertTrue(info.supported)
    }

    func testTiedEmbeddingsAreUnsupported() {
        let info = HuggingFaceModelInfo.parse(
            repo: "org/small", info: [:],
            config: ["architectures": ["LlamaForCausalLM"], "tie_word_embeddings": true, "num_hidden_layers": 16])
        XCTAssertFalse(info.supported)
        XCTAssertGreaterThan(info.sizeGB, 0, "falls back to estimating from layer shapes")
        XCTAssertTrue(info.asCatalogModel.blurb.contains("tied embeddings"))
    }

    func testOtherArchitecturesAreUnsupported() {
        let info = HuggingFaceModelInfo.parse(repo: "org/qwen", info: ["gated": false],
                                              config: ["architectures": ["Qwen2ForCausalLM"]])
        XCTAssertFalse(info.supported)
        XCTAssertFalse(info.gated)
    }

    func testLogoGuessesFromRepoName() {
        XCTAssertEqual(ModelCatalog.logo(for: "someone/DeepSeek-Coder"), "deepseek-color")
        XCTAssertEqual(ModelCatalog.logo(for: "someone/my-llama-finetune"), "meta-color")
        XCTAssertEqual(ModelCatalog.logo(for: "someone/unknown"), "huggingface-color")
        XCTAssertEqual(ModelCatalog.logo(for: nil), "huggingface-color")
    }

    func testDisplayName() {
        XCTAssertEqual(ModelCatalog.displayName("/Users/me/models/MyModel"), "MyModel")
        XCTAssertEqual(ModelCatalog.displayName("org/Some-Model"), "Some-Model")
    }

    func testConversationTitle() {
        XCTAssertEqual(Conversation.title(from: "Hello\nsecond line"), "Hello")
        let long = String(repeating: "a", count: 60)
        XCTAssertEqual(Conversation.title(from: long), String(repeating: "a", count: 45) + "…")
    }
}
