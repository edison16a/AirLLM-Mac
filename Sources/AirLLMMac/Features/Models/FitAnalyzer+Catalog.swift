import Foundation

extension FitAnalyzer {
    /// Runs the fit check for a picker entry using the user's settings and what's already on disk.
    @MainActor
    static func report(for model: CatalogModel, settings: AppSettings, info: SystemInfo) -> FitReport {
        analyze(sizeGB: model.sizeGB, layers: model.layers, largestShardGB: model.largestShardGB,
                download: ModelDownloads.state(of: model.repo, shardsPath: settings.layerShardsPath),
                info: info, inputs: SpeedEstimator.fitInputs(model: model.repo, settings: settings))
    }
}
