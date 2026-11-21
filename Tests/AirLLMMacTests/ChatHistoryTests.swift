import XCTest
@testable import AirLLMMac

@MainActor
final class ChatHistoryTests: XCTestCase {
    private func conversation(turns: Int) -> Conversation {
        var c = Conversation()
        for i in 0..<turns {
            c.messages.append(Message(role: .user, content: "q\(i)"))
            c.messages.append(Message(role: .assistant, content: "a\(i)"))
        }
        c.messages.append(Message(role: .user, content: "latest"))
        return c
    }

    func testKeepsSystemPromptAndRecentTurns() {
        let history = ChatController.history(for: conversation(turns: 5), systemPrompt: "Be brief.", turns: 2)
        XCTAssertEqual(history.first?.role, .system)
        XCTAssertEqual(history.dropFirst().map(\.content), ["q4", "a4", "latest"])
    }

    func testSkipsEmptyAndFailedMessages() {
        var c = conversation(turns: 1)
        var failed = Message(role: .assistant, content: "partial")
        failed.error = "boom"
        c.messages.append(failed)
        c.messages.append(Message(role: .assistant, content: ""))
        let history = ChatController.history(for: c, systemPrompt: "", turns: 10)
        XCTAssertEqual(history.map(\.content), ["q0", "a0", "latest"])
    }
}
