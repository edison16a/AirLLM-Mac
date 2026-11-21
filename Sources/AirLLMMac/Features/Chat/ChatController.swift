import Foundation
import Observation

/// Sends messages and streams replies into the conversation library.
@MainActor
@Observable
final class ChatController {
    private(set) var generatingConversation: Conversation.ID?
    private(set) var progress: GenProgress?
    private(set) var generatedTokens = 0
    private(set) var firstTokenAt: Date?
    private(set) var startedAt: Date?

    private let library: ConversationLibrary
    private let backend: BackendController
    private let settings: AppSettings
    private let systemInfo: () -> SystemInfo

    init(library: ConversationLibrary, backend: BackendController, settings: AppSettings,
         systemInfo: @escaping () -> SystemInfo) {
        self.library = library
        self.backend = backend
        self.settings = settings
        self.systemInfo = systemInfo
    }

    var isGenerating: Bool { generatingConversation != nil }

    func send(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating, backend.isReady, let i = library.index(of: library.selection) else { return }
        library.conversations[i].messages.append(Message(role: .user, content: text))
        if library.conversations[i].messages.count == 1 {
            library.conversations[i].title = Conversation.title(from: text)
        }
        generate(in: library.conversations[i].id)
    }

    func regenerate() {
        guard !isGenerating, let i = library.index(of: library.selection),
              library.conversations[i].messages.last?.role == .assistant else { return }
        library.conversations[i].messages.removeLast()
        generate(in: library.conversations[i].id)
    }

    func stop() { backend.stopGeneration() }

    /// Only the last few exchanges are sent. The model only knows what's in the prompt,
    /// and every prompt token adds to the wait before the first word.
    static func history(for conversation: Conversation, systemPrompt: String, turns: Int) -> [Message] {
        var history: [Message] = []
        let system = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !system.isEmpty { history.append(Message(role: .system, content: system)) }
        let usable = conversation.messages.filter { $0.error == nil && !$0.content.isEmpty }
        history += usable.suffix(max(1, turns * 2 - 1))
        return history
    }

    private func generate(in convID: Conversation.ID) {
        guard let i = library.index(of: convID), let model = backend.modelID else { return }
        let history = Self.history(for: library.conversations[i], systemPrompt: settings.systemPrompt,
                                   turns: settings.historyTurns)
        var reply = Message(role: .assistant, content: "")
        reply.modelID = model
        library.conversations[i].messages.append(reply)
        library.conversations[i].modelID = model
        library.conversations[i].updated = Date()
        library.moveToTop(convID)

        generatingConversation = convID
        progress = nil
        generatedTokens = 0
        firstTokenAt = nil
        startedAt = Date()

        let stream = backend.client.chat([
            "messages": history.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_new_tokens": settings.maxNewTokens,
            "temperature": settings.temperature,
        ])
        Task { [weak self] in
            do {
                for try await event in stream { self?.handle(event, convID: convID, msgID: reply.id, model: model) }
            } catch {
                self?.library.updateMessage(convID, reply.id) { $0.error = error.localizedDescription }
            }
            self?.finish(convID: convID, msgID: reply.id)
        }
    }

    private func handle(_ event: ChatEvent, convID: Conversation.ID, msgID: Message.ID, model: String) {
        switch event {
        case .progress(let p):
            progress = p
        case .token(let text):
            firstTokenAt = firstTokenAt ?? Date()
            generatedTokens += 1
            library.updateMessage(convID, msgID) { $0.content += text }
        case .done(let stats):
            library.updateMessage(convID, msgID) { m in
                m.stats = stats
                m.content = m.content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if !backend.isMock {
                SpeedEstimator.learn(from: stats, model: model, settings: settings, info: systemInfo())
            }
        case .error(let message):
            library.updateMessage(convID, msgID) { $0.error = message }
        }
    }

    private func finish(convID: Conversation.ID, msgID: Message.ID) {
        generatingConversation = nil
        progress = nil
        library.updateMessage(convID, msgID) { m in
            if m.content.isEmpty && m.error == nil && m.stats == nil { m.error = "No reply." }
        }
        library.scheduleSave()
    }

    // MARK: Estimates for the UI

    var secondsPerToken: Double? {
        SpeedEstimator.secondsPerToken(model: backend.modelID, isMock: backend.isMock,
                                       settings: settings, info: systemInfo())
    }

    var replyEstimate: (first: Double, full: Double)? {
        secondsPerToken.map { SpeedEstimator.replyEstimate(secondsPerToken: $0, maxTokens: settings.maxNewTokens) }
    }

    var remainingEstimate: Double? {
        guard isGenerating, let spt = secondsPerToken else { return nil }
        return SpeedEstimator.remaining(estimate: spt, generated: generatedTokens, maxTokens: settings.maxNewTokens,
                                        firstTokenAt: firstTokenAt, layerFraction: progress?.fraction ?? 0)
    }
}
