import AppKit

/// Handles the AppKit events SwiftUI's App doesn't expose, mainly quitting.
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Set by the app once its state exists. Saves chats and stops the Python server,
    /// which would otherwise linger and hold the port and the model's memory.
    var onTerminate: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Needed when launched with `swift run`, where there's no bundle to say this is a regular app.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        onTerminate?()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
