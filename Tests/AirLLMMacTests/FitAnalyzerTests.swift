import XCTest
@testable import AirLLMMac

final class FitAnalyzerTests: XCTestCase {
    private let mac16 = SystemInfo(ramGB: 16, freeDiskGB: 500, chipName: "Apple M2")

    private func analyze(sizeGB: Double, layers: Int = 32, shard: Double = 1,
                         download: DownloadState = .none, info: SystemInfo? = nil,
                         inputs: FitInputs = FitInputs()) -> FitReport {
        FitAnalyzer.analyze(sizeGB: sizeGB, layers: layers, largestShardGB: shard,
                            download: download, info: info ?? mac16, inputs: inputs)
    }

    func testSmallModelFitsInMemory() {
        XCTAssertEqual(analyze(sizeGB: 2.2).level, .inMemory)
    }

    func testLargeModelStreamsFromDisk() {
        XCTAssertEqual(analyze(sizeGB: 140, layers: 80).level, .streams)
    }

    func testNotEnoughDisk() {
        let tight = SystemInfo(ramGB: 16, freeDiskGB: 100, chipName: "")
        let report = analyze(sizeGB: 140, layers: 80, info: tight)
        XCTAssertEqual(report.level, .noDisk)
        XCTAssertFalse(report.level.canRun)
        XCTAssertTrue(report.explanation.contains("Delete original after splitting"))
    }

    func testHugeShardNeedsTooMuchMemory() {
        XCTAssertEqual(analyze(sizeGB: 20, shard: 8).level, .noMemory)
    }

    func testDiskNeededDependsOnWhatIsDownloaded() {
        XCTAssertEqual(FitAnalyzer.diskNeeded(sizeGB: 10, largestShardGB: 1, download: .split, deleteOriginal: false), 0)
        XCTAssertEqual(FitAnalyzer.diskNeeded(sizeGB: 10, largestShardGB: 1, download: .none, deleteOriginal: false), 20.5, accuracy: 0.001)
        XCTAssertEqual(FitAnalyzer.diskNeeded(sizeGB: 10, largestShardGB: 1, download: .none, deleteOriginal: true), 11, accuracy: 0.001)
        XCTAssertEqual(FitAnalyzer.diskNeeded(sizeGB: 10, largestShardGB: 1, download: .original, deleteOriginal: true), 2, accuracy: 0.001)
    }

    func testMeasuredSpeedWinsOverTheGuess() {
        let measured = FitAnalyzer.secondsPerToken(sizeGB: 16, layers: 32, cached: true,
                                                   inputs: FitInputs(measuredSecondsPerToken: 4.2))
        XCTAssertEqual(measured.value, 4.2)
        XCTAssertTrue(measured.measured)
    }

    func testGuessedSpeedUsesThroughputAndLayerOverhead() {
        let guess = FitAnalyzer.secondsPerToken(sizeGB: 12, layers: 10, cached: true, inputs: FitInputs())
        XCTAssertEqual(guess.value, 12 / FitAnalyzer.defaultCachedGBps + 10 * FitAnalyzer.perLayerOverhead, accuracy: 0.0001)
        XCTAssertFalse(guess.measured)
    }

    func testLearnedThroughputCountsAsCalibrated() {
        let learned = FitAnalyzer.secondsPerToken(sizeGB: 22, layers: 0, cached: false,
                                                  inputs: FitInputs(learnedDiskGBps: 1.1))
        XCTAssertEqual(learned.value, 20, accuracy: 0.0001)
        XCTAssertTrue(learned.measured)
    }
}
