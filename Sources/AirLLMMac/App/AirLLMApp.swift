import SwiftUI

/// Entry point. The real window content is wired in as each feature lands.
@main
struct AirLLMApp: App {
    var body: some Scene {
        WindowGroup("AirLLM") {
            Text("AirLLM")
                .frame(minWidth: 760, minHeight: 560)
        }
    }
}
