import XCTest
@testable import AirLLMMac

final class ChatEventParserTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 0)

    func testProgress() {
        guard case .progress(let p) = ChatEventParser.parse(
            #"{"type":"progress","phase":"prompt","token_index":0,"layer":3,"total":24}"#, startedAt: start)
        else { return XCTFail("expected progress") }
        XCTAssertEqual(p.phase, "prompt")
        XCTAssertEqual(p.layer, 3)
        XCTAssertEqual(p.fraction, 0.125)
    }

    func testToken() {
        guard case .token(let text) = ChatEventParser.parse(#"{"type":"token","text":" hi"}"#, startedAt: start)
        else { return XCTFail("expected token") }
        XCTAssertEqual(text, " hi")
    }

    func testDone() {
        let line = #"{"type":"done","tokens":5,"prompt_tokens":20,"seconds":9.0,"time_to_first_token":3.0,"reason":"eos"}"#
        guard case .done(let stats) = ChatEventParser.parse(line, startedAt: start)
        else { return XCTFail("expected done") }
        XCTAssertEqual(stats.tokens, 5)
        XCTAssertEqual(stats.reason, "eos")
        XCTAssertEqual(stats.steadySecondsPerToken ?? 0, 1.5, accuracy: 0.0001)
    }

    func testErrorAndJunk() {
        guard case .error(let message) = ChatEventParser.parse(#"{"type":"error","message":"boom"}"#, startedAt: start)
        else { return XCTFail("expected error") }
        XCTAssertEqual(message, "boom")
        XCTAssertNil(ChatEventParser.parse("not json", startedAt: start))
        XCTAssertNil(ChatEventParser.parse(#"{"type":"mystery"}"#, startedAt: start))
    }
}
