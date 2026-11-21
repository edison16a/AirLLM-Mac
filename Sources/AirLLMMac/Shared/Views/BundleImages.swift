import AppKit

/// Loads PNGs that ship in the app's Resources folder.
///
/// When running with `swift run` there's no app bundle, so it falls back to the
/// repo's Resources folder, found relative to this source file.
enum BundleImages {
    @MainActor private static var cache: [String: NSImage] = [:]

    @MainActor
    static func image(_ name: String, subdirectory: String? = nil) -> NSImage? {
        let key = (subdirectory ?? "") + "/" + name
        if let cached = cache[key] { return cached }
        let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdirectory)
            ?? sourceTreeURL(name, subdirectory: subdirectory)
        guard let url, let image = NSImage(contentsOf: url) else { return nil }
        cache[key] = image
        return image
    }

    private static func sourceTreeURL(_ name: String, subdirectory: String?) -> URL? {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }  // up to the repo root
        url.appendPathComponent("Resources")
        if let subdirectory { url.appendPathComponent(subdirectory) }
        url.appendPathComponent(name + ".png")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
