import SwiftUI

/// A model provider's logo, like Meta or Mistral.
struct ProviderLogo: View {
    let name: String
    var size: CGFloat = 20
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        // The Nous Research mark is solid black, so dark mode gets its light version.
        let file = (name == "nousresearch" && scheme == .dark) ? "nousresearch-dark" : name
        Group {
            if let image = BundleImages.image(file, subdirectory: "logos") {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "cpu").resizable().scaledToFit().foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}
