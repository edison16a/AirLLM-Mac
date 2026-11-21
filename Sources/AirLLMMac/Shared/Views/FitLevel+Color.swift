import SwiftUI

extension FitLevel {
    /// Kept out of the model layer so fit analysis doesn't depend on SwiftUI.
    var color: Color {
        switch self {
        case .inMemory: return .green
        case .streams: return .blue
        case .noDisk, .noMemory: return .red
        }
    }
}
