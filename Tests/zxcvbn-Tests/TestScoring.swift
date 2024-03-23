import XCTest
@testable import zxcvbn

let EPSILON = 1e-10 // truncate to 10th decimal place
func truncateFloat(_ float: Double) -> Double {
    return round(float / EPSILON) * EPSILON
}
func approxEqual(_ actual: Double, _ expected: Double) -> Bool {
    return truncateFloat(actual) == truncateFloat(expected)
}

final class TestScoring: XCTestCase {
    var scoring: Scoring!
    let password = "0123456789"
    let excludeAdditive = true


    override func setUp() {
        super.setUp()
        scoring = Scoring()
    }
    func testNChoosek() {
        let nChooseK = scoring.nChooseK
        let testCases: [(n: Double, k: Double, result: Double)] = [
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

        let n: Double = 49
        let k: Double = 12
        XCTAssertEqual(nChooseK(n, k), nChooseK(n, n-k), "mirror identity")
        XCTAssertEqual(nChooseK(n, k), nChooseK(n-1, k-1) + nChooseK(n-1, k), "pascal's triangle identity")
    }

    func testMostGuessableMatchSequenceWithEmptySequenceReturnsSingleBruteForceMatch() {
        // returns one bruteforce match given an empty match sequence
        let result = scoring.mostGuessableMatchSequence(password: password, matches: [])
        XCTAssertEqual(result.sequence.count, 1)
        let m0 = result.sequence[0]
        XCTAssertEqual(m0.pattern, "bruteforce")
        XCTAssertEqual(m0.token, password)
        XCTAssertEqual(m0.i, 0)
        XCTAssertEqual(m0.j, 9)
    }

   func testMostGuessableMatchSequenceWithPrefixMatchReturnsMatchAndBruteForce() {
       // returns match + bruteforce when match covers a prefix of password
       let match = Match(i: 0, j: 5, token: password)
       match.guesses = 1
       let matches = [match]
       let result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
       XCTAssertEqual(result.sequence.count, 2)
       XCTAssertEqual(result.sequence[0], match)
       let matchResult = result.sequence[1]
       XCTAssertEqual(matchResult.pattern, "bruteforce")
       XCTAssertEqual(matchResult.i, 6)
       XCTAssertEqual(matchResult.j, 9)
   }

    func testMostGuessableMatchSequenceWithSuffixMatchReturnsMatchAndBruteForce() {
        // returns bruteforce + match when match covers a suffix
        let match = Match(i: 3, j: 9, token: password)
        match.guesses = 1
        let matches = [match]
        let result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.sequence.count, 2, "result.match.sequence.count == 2")
        let matchResult = result.sequence[0]
        XCTAssertEqual(matchResult.pattern, "bruteforce", "first match is bruteforce")
        XCTAssertEqual(matchResult.i, 0, "first match covers full prefix before second match")
        XCTAssertEqual(matchResult.j, 2, "first match covers full prefix before second match")
        XCTAssertEqual(result.sequence[1], match, "second match is the provided match object")
    }

    func testInfixMatch() {
        // returns bruteforce + match + bruteforce when match covers an infix
        let match = Match(i: 1, j: 8, token: password)
        match.guesses = 1
        let matches = [match]
        let result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.sequence.count, 3, "result.sequence.count == 3")
        XCTAssertEqual(result.sequence[1], match, "middle match is the provided match object")
        let match0 = result.sequence[0]
        let match2 = result.sequence[2]
        XCTAssertEqual(match0.pattern, "bruteforce", "first match is bruteforce")
        XCTAssertEqual(match2.pattern, "bruteforce", "third match is bruteforce")
        XCTAssertEqual(match0.i, 0, "first match covers full prefix before second match")
        XCTAssertEqual(match0.j, 0, "first match covers full prefix before second match")
        XCTAssertEqual(match2.i, 9, "third match covers full suffix after second match")
        XCTAssertEqual(match2.j, 9, "third match covers full suffix after second match")
    }

    func testLowerGuessesMatch() {
        // chooses lower-guesses match given two matches of the same span
        let match0 = Match(i: 0, j: 9, token: password)
        match0.guesses = 1
        let match1 = Match(i: 0, j: 9, token: password)
        match1.guesses = 2
        let matches = [match0, match1]
        var result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.sequence.count, 1, "result.sequence.count == 1")
        XCTAssertEqual(result.sequence[0], match0, "result.sequence[0] == m0")
        // make sure ordering doesn't matter
        match0.guesses = 3
        result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.sequence.count, 1, "result.sequence.count == 1")
        XCTAssertEqual(result.sequence[0], match1, "result.sequence[0] == m1")
    }

    func testWhenM0CoversM1AndM2ChooseM0WhenM0LessThanM1TimesM2TimesFact2() {
        // when m0 covers m1 and m2, choose [m0] when m0 < m1 * m2 * fact(2)
        let match0 = Match(i: 0, j: 9, token: password)
        match0.guesses = 3
        let match1 = Match(i: 0, j: 3, token: password)
        match1.guesses = 2
        let match2 = Match(i: 4, j: 9, token: password)
        match2.guesses = 1
        let matches = [match0, match1, match2]
        let result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.guesses, 3, "total guesses == 3")
        XCTAssertEqual(result.sequence, [match0], "sequence is [m0]")
    }

    func testWhenM0CoversM1AndM2ChooseM1M2WhenM0GreaterThanM1TimesM2TimesFact2() {
        // when m0 covers m1 and m2, choose [m1, m2] when m0 > m1 * m2 * fact(2)
        let match0 = Match(i: 0, j: 9, token: password)
        match0.guesses = 5
        let match1 = Match(i: 0, j: 3, token: password)
        match1.guesses = 2
        let match2 = Match(i: 4, j: 9, token: password)
        match2.guesses = 1
        let matches = [match0, match1, match2]
        let result = scoring.mostGuessableMatchSequence(password: password, matches: matches, excludeAdditive: excludeAdditive)
        XCTAssertEqual(result.guesses, 4, "total guesses == 4")
        XCTAssertEqual(result.sequence, [match1, match2], "sequence is [m1, m2]")
    }

    func testCalcGuesses() {
        // estimateGuesses returns cached guesses when available
        let match = Match(i: 0, j: 0, token: "")
        match.guesses = 1
        XCTAssertEqual(scoring.estimateGuesses(match: match, password: ""), 1, "estimateGuesses returns cached guesses when available")

        // estimateGuesses delegates based on pattern
        match.token = "1977"
        match.pattern = "date"
        match.year = 1977
        match.month = 7
        match.day = 14
        match.guesses = nil
        XCTAssertEqual(scoring.estimateGuesses(match: match, password: "1977"), scoring.dateGuesses(match: match), "estimateGuesses delegates based on pattern")
    }

    func testRepeatGuesses() {
        let testCases: [(String, String, Double)] = [
            ("aa", "a", 2),
            ("999", "9", 3),
            ("$$$$", "$", 4),
            ("abab", "ab", 2),
            ("batterystaplebatterystaplebatterystaple", "batterystaple", 3)
        ]

        for (token, baseToken, repeatCount) in testCases {
            let matches = Matching().omnimatch(password: baseToken)
            let mostGuessableMatchSequence = scoring.mostGuessableMatchSequence(password: baseToken, matches: matches)
            let baseGuesses = mostGuessableMatchSequence.guesses
            let match = Match(i: 0, j: 0, token: token)
            match.baseToken = baseToken
            match.baseGuesses = baseGuesses
            match.repeatCount = repeatCount
            let expectedGuesses = baseGuesses * repeatCount
            XCTAssertEqual(scoring.repeatGuesses(match: match), expectedGuesses, "the repeat pattern '\(token)' has guesses of \(expectedGuesses)")
        }
    }

    func testSequenceGuesses() {
        let testCases: [(String, Bool, Double)] = [
            ("ab",   true,  4 * 2),      // obvious start * len-2
            ("XYZ",  true,  26 * 3),     // base26 * len-3
            ("4567", true,  10 * 4),     // base10 * len-4
            ("7654", false, 10 * 4 * 2), // base10 * len 4 * descending
            ("ZYX",  false, 4 * 3 * 2)   // obvious start * len-3 * descending
        ]

        for (token, ascending, expectedGuesses) in testCases {
            let match = Match(i: 0, j: 0, token: token)
            match.ascending = ascending
            XCTAssertEqual(scoring.sequenceGuesses(match: match), expectedGuesses, "the sequence pattern '\(token)' has guesses of \(expectedGuesses)")
        }
    }

    func testRegexGuesses() {
        let match = Match(i: 0, j: 0, token: "aizocdk")
        match.regexMatch = ["aizocdk"]
        match.regexName = "alpha_lower"
        var expectedGuesses: Double = pow(26, 7)
        XCTAssertEqual(Double(scoring.regexGuesses(match: match)), expectedGuesses, "guesses of 26^7 for 7-char lowercase regex")

        match.token = "ag7C8"
        match.regexName = "alphanumeric"
        match.regexMatch = ["ag7C8"]
        expectedGuesses = pow(2 * 26 + 10, 5)
        XCTAssertEqual(Double(scoring.regexGuesses(match: match)), expectedGuesses, "guesses of 62^5 for 5-char alphanumeric regex")

        match.token = "1972"
        match.regexName = "recent_year"
        match.regexMatch = ["1972"]
        expectedGuesses = Double(abs(scoring.REFERENCE_YEAR - 1972))
        XCTAssertEqual(Double(scoring.regexGuesses(match: match)), expectedGuesses, "guesses of |year - REFERENCE_YEAR| for distant year matches")

        match.token = "2005"
        match.regexName = "recent_year"
        match.regexMatch = ["2005"]
        expectedGuesses = Double(scoring.MIN_YEAR_SPACE)
        XCTAssertEqual(Double(scoring.regexGuesses(match: match)), expectedGuesses, "guesses of MIN_YEAR_SPACE for a year close to REFERENCE_YEAR")
    }

   func testDateGuesses() {
       let match = Match(i: 0, j: 0, token: "1123")
       match.separator = ""
       match.year = 1923
       match.month = 1
       match.day = 1

       var expectedGuesses: Double = Double(365 * abs(scoring.REFERENCE_YEAR - match.year!))
       XCTAssertEqual(scoring.dateGuesses(match: match), expectedGuesses, "guesses for \(match.token) is 365 * distance_from_ref_year")

       match.token = "1/1/2010"
       match.separator = "/"
       match.year = 2010
       match.month = 1
       match.day = 1
       expectedGuesses = Double(365 * scoring.MIN_YEAR_SPACE * 4)
       XCTAssertEqual(scoring.dateGuesses(match: match), expectedGuesses, "recent years assume MIN_YEAR_SPACE. extra guesses are added for separators.")
   }

   func testDictionaryGuesses() {
       let match = Match(i: 0, j: 0, token: "aaaaa")
       match.rank = 32
       match.reversed = false
       var msg = "base guesses == the rank"
       XCTAssertEqual(scoring.dictionaryGuesses(match: match), 32, msg)

       match.token = "AAAaaa"
       msg = "extra guesses are added for capitalization"
       XCTAssertEqual(scoring.dictionaryGuesses(match: match), 32 * scoring.uppercaseVariations(match: match), msg)

       match.token = "aaa"
       match.reversed = true
       msg = "guesses are doubled when word is reversed"
       XCTAssertEqual(scoring.dictionaryGuesses(match: match), 32 * 2, msg)

       match.token = "aaa@@@"
       match.l33t = true
       match.sub = ["@": "a"]
       match.reversed = false
       msg = "extra guesses are added for common l33t substitutions"
       XCTAssertEqual(scoring.dictionaryGuesses(match: match), 32 * scoring.l33tVariations(match: match), msg)

       match.token = "AaA@@@"
       msg = "extra guesses are added for both capitalization and common l33t substitutions"
       let expected = 32 * scoring.l33tVariations(match: match) * scoring.uppercaseVariations(match: match)
       XCTAssertEqual(scoring.dictionaryGuesses(match: match), expected, msg)
   }

    func testUppercaseVariants() {
        let testCases: [(String, Double)] = [
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
        let testCases: [(String, Double, [Character: Character])] = [
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
