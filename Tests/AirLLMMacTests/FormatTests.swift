import XCTest
@testable import AirLLMMac

final class FormatTests: XCTestCase {
    func testGigabytes() {
        XCTAssertEqual(Format.gigabytes(2.24), "2.2 GB")
        XCTAssertEqual(Format.gigabytes(141), "141 GB")
        XCTAssertEqual(Format.gigabytes(1600), "1.6 TB")
    }

    func testDuration() {
        XCTAssertEqual(Format.duration(4.25), "4.2s")
        XCTAssertEqual(Format.duration(42), "42s")
        XCTAssertEqual(Format.duration(120), "2m")
        XCTAssertEqual(Format.duration(125), "2m 5s")
        XCTAssertEqual(Format.duration(3 * 3600 + 7 * 60), "3h 7m")
    }

    func testSpeedSwitchesUnitsWithScale() {
        XCTAssertEqual(Format.speed(secondsPerToken: 0.25), "4.0 tok/s")
        XCTAssertEqual(Format.speed(secondsPerToken: 12), "12 s/token")
        XCTAssertEqual(Format.speed(secondsPerToken: 90), "1.5 min/token")
    }
}
