import XCTest
@testable import zxcvbn_swift

let EPSILON = 1e-10 // truncate to 10th decimal place
func truncateFloat(_ float: Double) -> Double {
    return round(float / EPSILON) * EPSILON
}
func approxEqual(_ actual: Double, _ expected: Double) -> Bool {
    return truncateFloat(actual) == truncateFloat(expected)
}

final class testScoring: XCTestCase {

    func testNChoosek() {
      let nChooseK = Scoring.nChoosek
      let testCases = [
          (n: 0, k: 0, result: 1),
          (n: 1, k: 0, result: 1),
          (n: 5, k: 0, result: 1),
          (n: 0, k: 1, result: 0),
          (n: 0, k: 5, result: 0),
          (n: 2, k: 1, result: 2),
          (n: 4, k: 2, result: 6),
          (n: 33, k: 7, result: 4272048)
      ]

      for testCase in testCases {
          XCTAssertEqual(nChoosek(testCase.n, testCase.k), testCase.result, "nChoosek(\(testCase.n), \(testCase.k)) == \(testCase.result)")
      }

      let n = 49
      let k = 12
      XCTAssertEqual(nChoosek(n, k), nChoosek(n, n-k), "mirror identity")
      XCTAssertEqual(nChoosek(n, k), nChoosek(n-1, k-1) + nChoosek(n-1, k), "pascal's triangle identity")
  }
}
