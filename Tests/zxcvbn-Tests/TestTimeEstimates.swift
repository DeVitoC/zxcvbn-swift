import XCTest
@testable import zxcvbn

class TimeEstimatesTests: XCTestCase {
    var timeEstimates: TimeEstimates!

    override func setUp() {
        super.setUp()
        timeEstimates = TimeEstimates()
    }

    func testEstimateAttackTimes() {
        var guesses: Double = 10
        var result = timeEstimates.estimateAttackTimes(guesses: guesses)

        // Test that the function correctly calculates the attack times
        XCTAssertEqual(result.crackTimesSeconds.onlineThrottling100PerHour, 360)
        XCTAssertEqual(result.crackTimesSeconds.onlineNoThrottling10PerSecond, 1)
        XCTAssertEqual(result.crackTimesSeconds.offlineSlowHashing1e4PerSecond, 0.001)
        XCTAssertEqual(result.crackTimesSeconds.offlineFastHashing1e10PerSecond, 1e-9)
        XCTAssertEqual(result.score, 0)

        guesses = 5000
        result = timeEstimates.estimateAttackTimes(guesses: guesses)

        // Test that the function correctly calculates the attack times
        XCTAssertEqual(result.crackTimesSeconds.onlineThrottling100PerHour, 1.8e5)
        XCTAssertEqual(result.crackTimesSeconds.onlineNoThrottling10PerSecond, 500)
        XCTAssertEqual(result.crackTimesSeconds.offlineSlowHashing1e4PerSecond, 0.5)
        XCTAssertEqual(result.crackTimesSeconds.offlineFastHashing1e10PerSecond, 5e-7)
        XCTAssertEqual(result.score, 1)

        guesses = 5e7
        result = timeEstimates.estimateAttackTimes(guesses: guesses)

        // Test that the function correctly calculates the attack times
        XCTAssertEqual(result.crackTimesSeconds.onlineThrottling100PerHour, 1.8e9)
        XCTAssertEqual(result.crackTimesSeconds.onlineNoThrottling10PerSecond, 5e6)
        XCTAssertEqual(result.crackTimesSeconds.offlineSlowHashing1e4PerSecond, 5000)
        XCTAssertEqual(result.crackTimesSeconds.offlineFastHashing1e10PerSecond, 5e-3)
        XCTAssertEqual(result.score, 2)

        guesses = 5e9
        result = timeEstimates.estimateAttackTimes(guesses: guesses)

        // Test that the function correctly calculates the attack times
        XCTAssertEqual(result.crackTimesSeconds.onlineThrottling100PerHour, 1.8e11)
        XCTAssertEqual(result.crackTimesSeconds.onlineNoThrottling10PerSecond, 5e8)
        XCTAssertEqual(result.crackTimesSeconds.offlineSlowHashing1e4PerSecond, 5e5)
        XCTAssertEqual(result.crackTimesSeconds.offlineFastHashing1e10PerSecond, 5e-1)
        XCTAssertEqual(result.score, 3)

        guesses = 5e11
        result = timeEstimates.estimateAttackTimes(guesses: guesses)

        // Test that the function correctly calculates the attack times
        XCTAssertEqual(result.crackTimesSeconds.onlineThrottling100PerHour, 1.8e13)
        XCTAssertEqual(result.crackTimesSeconds.onlineNoThrottling10PerSecond, 5e10)
        XCTAssertEqual(result.crackTimesSeconds.offlineSlowHashing1e4PerSecond, 5e7)
        XCTAssertEqual(result.crackTimesSeconds.offlineFastHashing1e10PerSecond, 50)
        XCTAssertEqual(result.score, 4)
    }
}
