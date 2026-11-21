import SwiftUI

/// The official AirLLM logo.
struct AirLLMLogo: View {
    var height: CGFloat
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if let image = BundleImages.image("AirLLMLogo") {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(height: height)
                // The wordmark is dark navy, so in dark mode it sits on a light tile to stay readable.
                .padding(scheme == .dark ? height * 0.14 : 0)
                .background {
                    if scheme == .dark {
                        RoundedRectangle(cornerRadius: height * 0.22, style: .continuous)
                            .fill(Color.white.opacity(0.92))
                    }
                }
        } else {
            Text("AirLLM").font(.largeTitle.bold())
        }
    }
}
