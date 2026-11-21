import Foundation
import Observation

/// The app's composition root. It builds each feature's controller once and
/// handles the few decisions that span features, like when to show setup.
@MainActor
@Observable
final class AppState {
    let settings: AppSettings
    let backend: BackendController
    let setup = SetupRunner()
    let library: ConversationLibrary
    let chat: ChatController
    var systemInfo = SystemInfo.current
    var showModelPicker = false

    /// Set after the first model choice of a backend session, so restarting a
    /// stopped backend doesn't keep reopening the picker.
    private var autoLoaded = false

    init(settings: AppSettings? = nil) {
        let settings = settings ?? AppSettings()
        self.settings = settings
        backend = BackendController(settings: settings)
        library = ConversationLibrary()
        chat = ChatController(library: library, backend: backend, settings: settings,
                              systemInfo: { SystemInfo.current })
    }

    /// Setup is needed until it has finished once and its Python still exists.
    /// Checking the file catches someone deleting the app's support folder.
    var needsSetup: Bool {
        let python = (settings.pythonPath as NSString).expandingTildeInPath
        return !settings.setupComplete || !FileManager.default.isExecutableFile(atPath: python)
    }

    func startIfReady() {
        if !needsSetup { backend.start() }
    }

    /// Called from the "You're all set" page, not from the runner, so that page gets seen.
    func finishSetup() {
        settings.setupComplete = true
        autoLoaded = false
        setup.finished = false
        backend.restart()
    }

    func rerunSetup() {
        backend.stop()
        setup.finished = false
        settings.setupComplete = false
    }

    /// The first time the backend reports it's empty, load the last model or ask for one.
    func backendStatusChanged() {
        guard !autoLoaded, backend.status == .noModel else { return }
        autoLoaded = true
        if settings.autoLoadLastModel, !settings.lastModel.isEmpty {
            loadModel(settings.lastModel)
        } else {
            showModelPicker = true
        }
    }

    func loadModel(_ id: String) {
        settings.lastModel = id
        Task { await backend.load(id, hfToken: Keychain.readToken()) }
    }

    func deleteConversation(_ id: Conversation.ID) {
        if chat.generatingConversation == id { chat.stop() }
        library.delete(id)
    }

    func refreshSystemInfo() { systemInfo = .current }

    /// Saves chats and stops the server. Called when the app quits.
    func shutdown() {
        library.saveNow()
        backend.stop()
    }
}
