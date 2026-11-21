import Foundation

/// A model the picker can offer, with just enough shape information to estimate
/// memory, disk and speed without downloading anything.
struct CatalogModel: Identifiable, Hashable {
    var id: String { repo }
    var repo: String
    var name: String
    var params: String
    /// Logo file name in Resources/logos.
    var provider: String
    /// Size of the fp16 weights in GB.
    var sizeGB: Double
    var layers: Int
    var vocab: Int = 128_256
    var hidden: Int = 4096
    var gated = false
    var blurb: String

    /// The biggest single file AirLLM holds in memory at once. Usually that is the
    /// embedding or output layer (vocab x hidden), which for Llama 3 is bigger than a
    /// transformer layer, so it sets the memory floor.
    var largestShardGB: Double {
        max(sizeGB / Double(max(layers, 1)) * 1.05, Double(vocab * hidden * 2) / 1_073_741_824)
    }

    var displayName: String { params.isEmpty ? name : "\(name) \(params)" }
}
