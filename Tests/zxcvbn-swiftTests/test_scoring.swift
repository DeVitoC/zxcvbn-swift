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
    var scoring: Scoring!

    override func setUp() {
        super.setUp()
        scoring = Scoring()
    }
    func testNChoosek() {
        let nChooseK = scoring.nChooseK
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
            XCTAssertEqual(nChooseK(testCase.n, testCase.k), testCase.result, "nChoosek(\(testCase.n), \(testCase.k)) == \(testCase.result)")
        }

        let n = 49
        let k = 12
        XCTAssertEqual(nChooseK(n, k), nChooseK(n, n-k), "mirror identity")
        XCTAssertEqual(nChooseK(n, k), nChooseK(n-1, k-1) + nChooseK(n-1, k), "pascal's triangle identity")
    }

    func testMostGuessableMatchSequenceWithEmptySequenceReturnsSingleBruteForceMatch() {
        let password = "0123456789"

        // returns one bruteforce match given an empty match sequence
        let result = scoring.mostGuessableMatchSequence(password: password, matches: [])
        XCTAssertEqual(result.sequence.count, 1)
        let m0 = result.sequence[0]
        XCTAssertEqual(m0.pattern, "bruteforce")
        XCTAssertEqual(m0.token, password)
        XCTAssertEqual(m0.i, 0)
        XCTAssertEqual(m0.j, 9)
    }

    func testMostGuessableMatchSequenceWithSuffixMatchReturnsMatchAndBruteForce() {
        let password = "0123456789"
        let excludeAdditive = true

        // returns bruteforce + match when match covers a suffix
        let m2 = Match(i: 3, j: 9, token: password)
        m2.guesses = 1
        let matches2 = [m2]
        let result2 = scoring.mostGuessableMatchSequence(password: password, matches: matches2, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result2.sequence.count, 2, "result.match.sequence.count == 2")
        let m2r = result2.sequence[0]
        XCTAssertEqual(m2r.pattern, "bruteforce", "first match is bruteforce")
        XCTAssertEqual(m2r.i, 0, "first match covers full prefix before second match")
        XCTAssertEqual(m2r.j, 2, "first match covers full prefix before second match")
        XCTAssertEqual(result2.sequence[1], matches2[0], "second match is the provided match object")
    }

    func testInfixMatch() {
        let password = "0123456789"
        let excludeAdditive = true

        // returns bruteforce + match + bruteforce when match covers an infix
        let m1 = Match(i: 1, j: 8, token: password)
        m1.guesses = 1
        let matches = [m1]
        let result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.sequence.count, 3, "result.sequence.count == 3")
        XCTAssertEqual(result.sequence[1], m1, "middle match is the provided match object")
        let m0 = result.sequence[0]
        let m2 = result.sequence[2]
        XCTAssertEqual(m0.pattern, "bruteforce", "first match is bruteforce")
        XCTAssertEqual(m2.pattern, "bruteforce", "third match is bruteforce")
        XCTAssertEqual(m0.i, 0, "first match covers full prefix before second match")
        XCTAssertEqual(m0.j, 0, "first match covers full prefix before second match")
        XCTAssertEqual(m2.i, 9, "third match covers full suffix after second match")
        XCTAssertEqual(m2.j, 9, "third match covers full suffix after second match")
    }

    func testCalcGuesses() {
        // estimateGuesses returns cached guesses when available
        var match = Match(i: 0, j: 0, token: "")
        match.guesses = 1
        XCTAssertEqual(scoring.estimateGuesses(match: match, password: ""), 1, "estimateGuesses returns cached guesses when available")

        // estimateGuesses delegates based on pattern
        match = Match(i: 0, j: 0, token: "1977")
        match.pattern = "date"
        match.year = 1977
        match.month = 7
        match.day = 14
        XCTAssertEqual(scoring.estimateGuesses(match: match, password: "1977"), scoring.dateGuesses(match: match), "estimateGuesses delegates based on pattern")
    }

    func testRepeatGuesses() {
        let testCases = [
            ("aa", "a", 2),
            ("999", "9", 3),
            ("$$$$", "$", 4),
            ("abab", "ab", 2),
            ("batterystaplebatterystaplebatterystaple", "batterystaple", 3)
        ]

        for testCase in testCases {
            let (token, baseToken, repeatCount) = testCase
            let baseGuesses = scoring.mostGuessableMatchSequence(password: baseToken, matches: Matcher().omnimatch(baseToken, userInputs: []), excludeAdditive: true).guesses
            let match = Match(i: 0, j: 0, token: token)
            match.baseToken = baseToken
            match.baseGuesses = Int(baseGuesses)
            match.repeatCount = repeatCount
            let expectedGuesses = Int(baseGuesses) * repeatCount
            XCTAssertEqual(scoring.repeatGuesses(match: match), expectedGuesses, "the repeat pattern '\(token)' has guesses of \(expectedGuesses)")
        }
    }

    func testSequenceGuesses() {
        let testCases = [
            ("ab",   true,  4 * 2),      // obvious start * len-2
            ("XYZ",  true,  26 * 3),     // base26 * len-3
            ("4567", true,  10 * 4),     // base10 * len-4
            ("7654", false, 10 * 4 * 2), // base10 * len 4 * descending
            ("ZYX",  false, 4 * 3 * 2)   // obvious start * len-3 * descending
        ]

        for testCase in testCases {
            let (token, ascending, expectedGuesses) = testCase
            let match = Match(i: 0, j: 0, token: token)
            match.ascending = ascending
            XCTAssertEqual(scoring.sequenceGuesses(match: match), expectedGuesses, "the sequence pattern '\(token)' has guesses of \(expectedGuesses)")
        }
    }

    func testUppercaseVariants() {
        let testCases: [(String, Int)] = [
            ("", 1),
            ("a", 1),
            ("A", 2),
            ("abcdef", 1),
            ("Abcdef", 2),
            ("abcdeF", 2),
            ("ABCDEF", 2),
            ("aBcdef", scoring.nChooseK(6, 1)),
            ("aBcDef", scoring.nChooseK(6, 1) + scoring.nChooseK(6, 2)),
            ("ABCDEf", scoring.nChooseK(6, 1)),
            ("aBCDEf", scoring.nChooseK(6, 1) + scoring.nChooseK(6, 2)),
            ("ABCdef", scoring.nChooseK(6, 1) + scoring.nChooseK(6, 2) + scoring.nChooseK(6, 3))
        ]

        for testCase in testCases {
            let (token, expectedVariants) = testCase
            let msg = "guess multiplier of \(token) is \(expectedVariants)"
            let match = Match(i: 0, j: 0, token: token)
            XCTAssertEqual(scoring.uppercaseVariations(match: match), expectedVariants, msg)
        }
    }

    func testL33tVariants() {
        let testCases = [
            ("", 1, [:]),
            ("a", 1, [:]),
            ("4", 2, ["4": "a"]),
            ("4pple", 2, ["4": "a"]),
            ("abcet", 1, [:]),
            ("4bcet", 2, ["4": "a"]),
            ("a8cet", 2, ["8": "b"]),
            ("abce+", 2, ["+": "t"]),
            ("48cet", 4, ["4": "a", "8": "b"]),
            ("a4a4aa", scoring.nChooseK(6, 2) + scoring.nChooseK(6, 1), ["4": "a"]),
            ("4a4a44", scoring.nChooseK(6, 2) + scoring.nChooseK(6, 1), ["4": "a"]),
            ("a44att+", (scoring.nChooseK(4, 2) + scoring.nChooseK(4, 1)) * scoring.nChooseK(3, 1), ["4": "a", "+": "t"])
        ]

        for testCase in testCases {
            let (token, expectedVariants, sub) = testCase
            let match = Match(i: 0, j: 0, token: token)
            match.sub = sub
            match.l33t = !sub.isEmpty
            let msg = "extra l33t guesses of \(token) is \(expectedVariants)"
            XCTAssertEqual(scoring.l33tVariations(match: match), expectedVariants, msg)
        }

        let match = Match(i: 0, j: 0, token: "Aa44aA")
        match.l33t = true
        match.sub = ["4": "a"]
        let variants = scoring.nChooseK(6, 2) + scoring.nChooseK(6, 1)
        let msg = "capitalization doesn't affect extra l33t guesses calc"
        XCTAssertEqual(scoring.l33tVariations(match: match), variants, msg)
    }
}
