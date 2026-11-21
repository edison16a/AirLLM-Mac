import XCTest
@testable import AirLLMMac

@MainActor
final class SpeedEstimatorTests: XCTestCase {
    func testReplyEstimateAddsPromptCostToFirstToken() {
        let estimate = SpeedEstimator.replyEstimate(secondsPerToken: 2, maxTokens: 100)
        XCTAssertEqual(estimate.first, 2.6, accuracy: 0.0001)
        XCTAssertEqual(estimate.full, 202.6, accuracy: 0.0001)
    }

    func testRemainingBeforeFirstToken() {
        let left = SpeedEstimator.remaining(estimate: 1, generated: 0, maxTokens: 10,
                                            firstTokenAt: nil, layerFraction: 0.5)
        XCTAssertEqual(left, 9.5 + 0.3, accuracy: 0.0001)
    }

    func testRemainingUsesObservedSpeed() {
        let start = Date(timeIntervalSince1970: 1000)
        let now = start.addingTimeInterval(9)
        // Four tokens after the first one took nine seconds, so 3 s/token for the six left.
        let left = SpeedEstimator.remaining(estimate: 100, generated: 4, maxTokens: 10,
                                            firstTokenAt: start, layerFraction: 0, now: now)
        XCTAssertEqual(left, 18, accuracy: 0.0001)
    }

    func testRemainingNeverGoesNegative() {
        XCTAssertEqual(SpeedEstimator.remaining(estimate: 1, generated: 12, maxTokens: 10,
                                                firstTokenAt: nil, layerFraction: 0.9), 0)
    }
}
