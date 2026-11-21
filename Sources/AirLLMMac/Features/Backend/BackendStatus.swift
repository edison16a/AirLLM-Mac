import Foundation

enum BackendStatus: Equatable {
    case stopped
    case starting
    case noModel
    case loading(model: String)
    case ready(model: String, layers: Int?)
    case failed(String)

    var modelID: String? {
        if case .ready(let m, _) = self { return m }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

/// The JSON the server returns from GET /health.
struct BackendHealth: Decodable, Equatable {
    var model_id: String?
    var loading: Bool
    var loading_model: String?
    var error: String?
    var n_layers: Int?
    var log: [String]?
    var mock: Bool?

    var status: BackendStatus {
        if loading, let m = loading_model { return .loading(model: m) }
        if let m = model_id { return .ready(model: m, layers: n_layers) }
        return .noModel
    }
}
