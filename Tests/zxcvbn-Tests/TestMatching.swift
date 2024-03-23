//
//  TestMatching.swift
//  
//
//  Created by Christopher DeVito on 3/9/24.
//

import XCTest
@testable import zxcvbn

final class TestMatching: XCTestCase {
    var matching: Matching!
    var matchingHelpers = MatchingHelpers.shared

    override func setUp() {
        super.setUp()
        matching = Matching()
    }

    func checkMatches(_ prefix: String, _ matches: [Match], _ patternNames: String, _ patterns: [String], _ ijs: [(Int, Int)], _ props: [String: [Any]]) {
        let patternNames = Array(repeating: patternNames, count: patterns.count)
        let isEqualLenArgs = patternNames.count == patterns.count && patterns.count == ijs.count
        for (_, lst) in props {
            if !isEqualLenArgs || lst.count != patterns.count {
                XCTFail("unequal argument lists to check_matches")
            }
        }

        let msg = "\(prefix): len(matches) == \(patterns.count)"
        XCTAssertEqual(matches.count, patterns.count, msg)

        for k in 0..<patterns.count {
            let match = matches[k]
            let kIndex = patternNames.index(patternNames.startIndex, offsetBy: k)
            let patternName = String(patternNames[kIndex])
            let pattern = patterns[k]
            let (i, j) = ijs[k]

            var msg = "\(prefix): matches[\(k)]['pattern'] == '\(patternName)'"
            XCTAssertEqual(match.pattern, patternName, msg)

            msg = "\(prefix): matches[\(k)] should have [i, j] of [\(i), \(j)]"
            XCTAssertEqual([match.i, match.j], [i, j], msg)

            msg = "\(prefix): matches[\(k)]['token'] == '\(pattern)'"
            XCTAssertEqual(match.token, pattern, msg)

            for (propName, propList) in props {
                let propMsg = propList[k]
                let msg = "\(prefix): matches[\(k)].\(propName) == \(propMsg)"
                switch propName {
                    case "matchedWord":
                        XCTAssertEqual(match.matchedWord, propList[k] as? String, msg)
                    case "rank":
                        XCTAssertEqual(match.rank, propList[k] as? Double, msg)
                    case "dictionaryName":
                        XCTAssertEqual(match.dictionaryName, propList[k] as? String, msg)
                    case "reversed":
                        XCTAssertEqual(match.reversed, propList[k] as? Bool, msg)
                    case "l33t":
                        XCTAssertEqual(match.l33t, propList[k] as? Bool, msg)
                    case "sub":
                        let kPropList = (propList[k] as? [Character: Character]) ?? [:]
                        let matchSub = match.sub ?? [:]
                        XCTAssertEqual(matchSub, kPropList, msg)
                    case "graph":
                        XCTAssertEqual(match.graph, propList[k] as? String, msg)
                    case "turns":
                        XCTAssertEqual(match.turns, propList[k] as? Int, msg)
                    case "shifted_count":
                        XCTAssertEqual(match.shiftedCount, propList[k] as? Int, msg)
                    case "ascending":
                        XCTAssertEqual(match.ascending, propList[k] as? Bool, msg)
                    case "sequenceName":
                        XCTAssertEqual(match.sequenceName, propList[k] as? String, msg)
                    case "baseToken":
                        XCTAssertEqual(match.baseToken, propList[k] as? String, msg)
                    case "separator":
                        XCTAssertEqual(match.separator, (propList[k] as? String), msg)
                    case "regexName":
                        XCTAssertEqual(match.regexName, propList[k] as? String, msg)
                    case "year":
                        XCTAssertEqual(match.year, propList[k] as? Int, msg)
                    case "month":
                        XCTAssertEqual(match.month, propList[k] as? Int, msg)
                    case "day":
                        XCTAssertEqual(match.day, propList[k] as? Int, msg)
                    default:
                        break
                }
            }
        }
    }

    func genpws(pattern: String, prefixes: [String], suffixes: [String]) -> [(String, Int, Int)]{
        var prefixes: [String] = prefixes
        var suffixes: [String] = suffixes
        for (index, lst) in [prefixes, suffixes].enumerated() {
            if !lst.contains("") {
                switch index {
                    case 0:
                        prefixes.insert("", at: 0)
                    default:
                        suffixes.insert("", at: 0)
                }
            }
        }
        var result: [(String, Int, Int)] = []
        for prefix in prefixes {
            for suffix in suffixes {
                let i = prefix.count
                let j = prefix.count + pattern.count - 1
                result.append((prefix + pattern + suffix, i, j))
            }
        }
        return result
    }

    func testDictionaryMatching() {
        let testDicts = [
            "d1": ["motherboard": 1, "mother": 2, "board": 3, "abcd": 4, "cdef": 5],
            "d2": ["z": 1, "8": 2, "99": 3, "$": 4, "asdf1234&*": 5]
        ]

        func dm(_ pw: String) -> [Match] {
            return matching.dictionaryMatch(password: pw, rankedDictionaries: testDicts)
        }

        let matches = dm("motherboard")
        let patterns = ["mother", "motherboard", "board"]
        let msg = "matches words that contain other words"
        checkMatches(
            msg,
            matches,
            "dictionary",
            patterns,
            [(0, 5), (0, 10), (6, 10)],
            [
                "matchedWord": ["mother", "motherboard", "board"],
                "rank": [2.0, 1.0, 3.0],
                "dictionary_name": ["d1", "d1", "d1"]
            ]
        )

        let matches2 = dm("abcdef")
        let patterns2 = ["abcd", "cdef"]
        let msg2 = "matches multiple words when they overlap"
        checkMatches(
            msg2,
            matches2, 
            "dictionary",
            patterns2,
            [(0, 3), (2, 5)],
            [
                "matched_word": ["abcd", "cdef"],
                "rank": [4.0, 5.0],
                "dictionary_name": ["d1", "d1"]
            ]
        )

        let matches3 = dm("BoaRdZ")
        let patterns3 = ["BoaRd", "Z"]
        let msg3 = "ignores uppercasing"
        checkMatches(
            msg3,
            matches3,
            "dictionary",
            patterns3,
            [(0, 4), (5, 5)],
            [
                "matched_word": ["board", "z"],
                "rank": [3.0, 1.0],
                "dictionary_name": ["d1", "d2"]
            ]
        )

        let prefixes = ["q", "%%"]
        let suffixes = ["%", "qq"]
        let word = "asdf1234&*"
        for (password, i, j) in genpws(pattern: word, prefixes: prefixes, suffixes: suffixes) {
            let matches = dm(password)
            let msg = "identifies words surrounded by non-words"
            checkMatches(
                msg,
                matches,
                "dictionary",
                [word],
                [(i, j)],
                [
                    "matched_word": [word],
                    "rank": [5.0],
                    "dictionary_name": ["d2"]
                ]
            )
        }

        for (name, dict) in testDicts {
            for (word, rank) in dict {
                if word == "motherboard" {
                    continue // skip words that contain others
                }
                let matches = dm(word)
                let msg = "matches against all words in provided dictionaries"
                checkMatches(
                    msg,
                    matches,
                    "dictionary",
                    [word],
                    [(0, word.count - 1)],
                    [
                        "matched_word": [word],
                        "rank": [Double(rank)],
                        "dictionary_name": [name]
                    ]
                )
            }
        }

        // test the default dictionaries
        let matches4 = matching.dictionaryMatch(password: "wow", rankedDictionaries: matching.rankedDictionaries)
        let patterns4 = ["wow"]
        let ijs4 = [(0, 2)]
        let msg4 = "default dictionaries"
        checkMatches(
            msg4,
            matches4,
            "dictionary",
            patterns4,
            ijs4,
            [
                "matched_word": patterns4,
                "rank": [322.0],
                "dictionary_name": ["us_tv_and_film"]
            ]
        )
    }

    func testReverseDictionaryMatching() {
        let testDicts = ["d1": ["123": 1, "321": 2, "456": 3, "654": 4]]
        let password = "0123456789"
        let matches = matching.reverseDictionaryMatch(password: password, rankedDictionaries: testDicts)
        let msg = "matches against reversed words"
        checkMatches(
            msg,
            matches,
            "dictionary",
            ["123", "456"],
            [(1, 3), (4, 6)],
            [
                "matched_word": ["321", "654"],
                "reversed": [true, true],
                "dictionary_name": ["d1", "d1"],
                "rank": [2.0, 4.0]
            ]
        )
    }

    func testL33tMatching() {
        let testTable: [Character: [Character]] = ["a": ["4", "@"], "c": ["(", "{", "[", "<"], "g": ["6", "9"], "o": ["0"]]

        func lm(_ pw: String) -> [Match] {
            let matches = matching.l33tMatch(password: pw, rankedDictionaries: testDicts, table: testTable)
            return matches
        }

        let testDicts = [
            "words": ["aac": 1, "password": 3, "paassword": 4, "asdf0": 5],
            "words2": ["cgo": 1]
        ]

        XCTAssertEqual(lm(""), [], "doesn't match ''")
        XCTAssertEqual(lm("password"), [], "doesn't match pure dictionary words")

        let testCases: [(String, String, String, String, Double, (Int, Int), [Character: Character])] = [
            ("p4ssword", "p4ssword", "password", "words", 3.0, (0, 7), ["4": "a"]),
            ("p@ssw0rd", "p@ssw0rd", "password", "words", 3.0, (0, 7), ["@": "a", "0": "o"]),
            ("aSdfO{G0asDfO", "{G0", "cgo", "words2", 1.0, (5, 7), ["{": "c", "0": "o"])
        ]

        for (password, pattern, word, dictionaryName, rank, ij, sub) in testCases {
            let msg = "matches against common l33t substitutions"
            checkMatches(
                msg,
                lm(password),
                "dictionary",
                [pattern],
                [ij],
                [
                    "l33t": [true],
                    "sub": [sub],
                    "matched_word": [word],
                    "rank": [rank],
                    "dictionary_name": [dictionaryName]
                ]
            )
        }

        let matches = lm("@a(go{G0")
        let msg = "matches against overlapping l33t patterns"
        let sub: [[Character: Character]] = [["@": "a", "(": "c"], ["(": "c"], ["{": "c", "0": "o"]]
        checkMatches(
            msg,
            matches,
            "dictionary",
            ["@a(", "(go", "{G0"],
            [(0, 2), (2, 4), (5, 7)],
            [
                "l33t": [true, true, true],
                "sub": sub,
                "matched_word": ["aac", "cgo", "cgo"],
                "rank": [1.0, 1.0, 1.0],
                "dictionary_name": ["words", "words2", "words2"]
            ]
        )

        let msg2 = "doesn't match when multiple l33t substitutions are needed for the same letter"
        XCTAssertEqual(lm("p4@ssword"), [], msg2)

        let msg3 = "doesn't match single-character l33ted words"
        XCTAssertEqual(matching.l33tMatch(password: "4 1 @", rankedDictionaries: [:], table: [:]), [], msg3)

        // known issue: subsets of substitutions aren't tried.
        // for long inputs, trying every subset of every possible substitution could quickly get large,
        // but there might be a performant way to fix.
        // (so in this example: {'4': a, '0': 'o'} is detected as a possible sub,
        // but the subset {'4': 'a'} isn't tried, missing the match for asdf0.)
        // TODO: consider partially fixing by trying all subsets of size 1 and maybe 2
        // let msg4 = "doesn't match with subsets of possible l33t substitutions"
        // let subsetMatches = lm("4sdf0")
        // XCTAssertEqual(subsetMatches, [], msg4)
    }

    func testSpatialMatching() {
        for password in ["", "/", "qw", "*/"] {
            let msg = "doesn't match 1- and 2-character spatial patterns"
            XCTAssertEqual(matching.spatialMatch(password: password, rankedDictionaries: [:]), [], msg)
        }

        // for testing, make a subgraph that contains a single keyboard
        let _graphs = ["qwerty": matching.graphs["qwerty"]!]
        let pattern = "6tfGHJ"
        let matches = matching.spatialMatch(password: "rz!\(pattern)%%z", graphs: _graphs, rankedDictionaries: matching.rankedDictionaries)
        let msg = "matches against spatial patterns surrounded by non-spatial patterns"
        checkMatches(
            msg,
            matches,
            "spatial",
            [pattern],
            [(3, 3 + pattern.count - 1)],
            [
                "graph": ["qwerty"],
                "turns": [2],
                "shiftedCount": [3]
            ]
        )

        let testCases = [
            ("12345", "qwerty", 1, 0),
            ("@WSX", "qwerty", 1, 4),
            ("6tfGHJ", "qwerty", 2, 3),
            ("hGFd", "qwerty", 1, 2),
            ("/;p09876yhn", "qwerty", 3, 0),
            ("Xdr%", "qwerty", 1, 2),
            ("159-", "keypad", 1, 0),
            ("*84", "keypad", 1, 0),
            ("/8520", "keypad", 1, 0),
            ("369", "keypad", 1, 0),
            ("/963.", "mac_keypad", 1, 0),
            ("*-632.0214", "mac_keypad", 9, 0),
            ("aoEP%yIxkjq:", "dvorak", 4, 5),
            (";qoaOQ:Aoq;a", "dvorak", 11, 4)
        ]

        for (pattern, keyboard, turns, shifts) in testCases {
            let _graphs = [keyboard: matching.graphs[keyboard]!]
            let matches = matching.spatialMatch(password: pattern, graphs: _graphs, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches '\(pattern)' as a \(keyboard) pattern"
            checkMatches(
                msg,
                matches,
                "spatial",
                [pattern],
                [(0, pattern.count - 1)],
                [
                    "graph": [keyboard],
                    "turns": [turns],
                    "shiftedCount": [shifts]
                ]
            )
        }
    }

    func testSequenceMatching() {
        for password in ["", "a", "1"] {
            let msg = "doesn't match length-\(password.count) sequences"
            XCTAssertEqual(matching.sequenceMatch(password: password, rankedDictionaries: matching.rankedDictionaries), [], msg)
        }

        let matches = matching.sequenceMatch(password: "abcbabc", rankedDictionaries: matching.rankedDictionaries)
        let msg = "matches overlapping patterns"
        checkMatches(
            msg,
            matches,
            "sequence",
            ["abc", "cba", "abc"],
            [(0, 2), (2, 4), (4, 6)],
            [
                "ascending": [true, false, true]
            ]
        )

        let prefixes = ["!", "22"]
        let suffixes = ["!", "22"]
        let pattern = "jihg"
        for (password, i, j) in genpws(pattern: pattern, prefixes: prefixes, suffixes: suffixes) {
            let matches = matching.sequenceMatch(
                password: password,
                rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches embedded sequence patterns"
            checkMatches(
                msg,
                matches,
                "sequence",
                [pattern],
                [(i, j)],
                [
                    "sequenceName": ["lower"],
                    "ascending": [false]
                ]
            )
        }

        let testCases = [
            ("ABC", "upper", true),
            ("CBA", "upper", false),
            ("PQR", "upper", true),
            ("RQP", "upper", false),
            ("XYZ", "upper", true),
            ("ZYX", "upper", false),
            ("abcd", "lower", true),
            ("dcba", "lower", false),
            ("jihg", "lower", false),
            ("wxyz", "lower", true),
            ("zxvt", "lower", false),
            ("0369", "digits", true),
            ("97531", "digits", false)
        ]

        for (pattern, name, isAscending) in testCases {
            let matches = matching.sequenceMatch(password: pattern, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches '\(pattern)' as a '\(name)' sequence"
            checkMatches(
                msg,
                matches,
                "sequence",
                [pattern],
                [(0, pattern.count - 1)],
                [
                    "sequenceName": [name],
                    "ascending": [isAscending]
                ]
            )
        }
    }

    func testRepeatMatching() {
        // Test empty and single-character passwords
        let emptyAndSingleCharPasswords = ["", "#"]
        for password in emptyAndSingleCharPasswords {
            XCTAssertTrue(matching.repeatMatch(password: password, rankedDictionaries: matching.rankedDictionaries).isEmpty, "doesn't match length-\(password.count) repeat patterns")
        }

        // Test single-character repeats with prefixes and suffixes
        let prefixes = ["@", "y4@"]
        let suffixes = ["u", "u%7"]
        let pattern = "&&&&&"
        for (password, i, j) in genpws(pattern: pattern, prefixes: prefixes, suffixes: suffixes) {
            let matches = matching.repeatMatch(password: password, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches embedded repeat patterns"
            checkMatches(
                msg,
                matches,
                "repeat",
                [pattern],
                [(i, j)],
                [
                    "baseToken": ["&"]
                ]
            )
        }

        // Test repeats with different base characters and lengths
        for length in [3, 12] {
            for chr in ["a", "Z", "4", "&"] {
                let pattern = String(repeating: chr, count: length + 1)
                let matches = matching.repeatMatch(password: pattern, rankedDictionaries: matching.rankedDictionaries)
                let msg = "matches repeats with base character '\(chr)'"
                checkMatches(
                    msg,
                    matches,
                    "repeat",
                    [pattern],
                    [(0, pattern.count - 1)],
                    [
                        "baseToken": [chr]
                    ]
                )
            }
        }

        // Test multiple adjacent repeats
        let multiplePatternsPassword = "BBB1111aaaaa@@@@@@"
        let patterns = ["BBB", "1111", "aaaaa", "@@@@@@"]
        let matches = matching.repeatMatch(password: multiplePatternsPassword, rankedDictionaries: matching.rankedDictionaries)
        let msg = "matches multiple adjacent repeats"
        checkMatches(
            msg,
            matches,
            "repeat",
            patterns,
            [(0, 2), (3, 6), (7, 11), (12, 17)],
            [
                "baseToken": ["B", "1", "a", "@"]
            ]
        )

        // Test multiple repeats with non-repeats in-between
        let complexPassword = "2818BBBbzsdf1111@*&@!aaaaaEUDA@@@@@@1729"
        let matches2 = matching.repeatMatch(password: complexPassword, rankedDictionaries: matching.rankedDictionaries)
        let msg2 = "matches multiple repeats with non-repeats in-between"
        checkMatches(
            msg2,
            matches2,
            "repeat",
            patterns,
            [(4, 6), (12, 15), (21, 25), (30, 35)],
            [
                "baseToken": ["B", "1", "a", "@"]
            ]
        )

        // Test multi-character repeats
        let multiCharPattern = "abab"
        let matches3 = matching.repeatMatch(password: multiCharPattern, rankedDictionaries: matching.rankedDictionaries)
        let msg3 = "matches multi-character repeat pattern"
        checkMatches(
            msg3,
            matches3,
            "repeat",
            [multiCharPattern],
            [(0, multiCharPattern.count - 1)],
            [
                "baseToken": ["ab"]
            ]
        )

        let aabPattern = "aabaab"
        let matches4 = matching.repeatMatch(password: aabPattern, rankedDictionaries: matching.rankedDictionaries)
        let msg4 = "matches aabaab as a repeat instead of the aa prefix"
        checkMatches(
            msg4,
            matches4,
            "repeat",
            [aabPattern],
            [(0, aabPattern.count - 1)],
            [
                "baseToken": ["aab"]
            ]
        )

        let abPattern = "abababab"
        let matches5 = matching.repeatMatch(password: abPattern, rankedDictionaries: matching.rankedDictionaries)
        let msg5 = "identifies ab as repeat string, even though abab is also repeated"
        checkMatches(
            msg5,
            matches5,
            "repeat",
            [abPattern],
            [(0, abPattern.count - 1)],
            [
                "baseToken": ["ab"]
            ]
        )
    }

    func testRegexMatching() {
        let testCases = [
            ("1922", "recentYear"),
            ("2017", "recentYear")
        ]

        for (pattern, name) in testCases {
            let matches = matching.regexMatch(password: pattern, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches \(pattern) as a \(name) pattern"
            checkMatches(
                msg,
                matches,
                "regex",
                [pattern],
                [(0, pattern.count - 1)],
                [
                    "regexName": [name]
                ]
            )
        }
    }

    func testDateMatching() {
        // Test dates with different separators
        let separators = ["", " ", "-", "/", "\\", "_", "."]
        for sep in separators {
            let password = "13\(sep)2\(sep)1921"
            let matches = matching.dateMatch(password: password, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches dates that use '\(sep)' as a separator"
            checkMatches(
                msg,
                matches,
                "date",
                [password],
                [(0, password.count - 1)],
                [
                    "separator": [sep],
                    "year": [1921],
                    "month": [2],
                    "day": [13]
                ]
            )
        }

        // Test dates with different order formats
        let orders = ["mdy", "dmy", "ymd", "ydm"]
        for order in orders {
            let d = 8, m = 8, y = 88
            let password = order.replacingOccurrences(of: "y", with: "\(y)").replacingOccurrences(of: "m", with: "\(m)").replacingOccurrences(of: "d", with: "\(d)")
            let matches = matching.dateMatch(password: password, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches dates with '\(order)' format"
            checkMatches(
                msg,
                matches,
                "date",
                [password],
                [(0, password.count - 1)],
                [
                    "separator": [""],
                    "year": [1988],
                    "month": [8],
                    "day": [8]
                ]
            )
        }

        // Test ambiguous dates
        let password = "111504"
        let matches = matching.dateMatch(password: password, rankedDictionaries: matching.rankedDictionaries)
        let msg = "matches the date with year closest to REFERENCE_YEAR when ambiguous"
        checkMatches(
            msg,
            matches,
            "date",
            [password],
            [(0, password.count - 1)],
            [
                "separator": [""],
                "year": [2004], // Picks '04' -> 2004 as year, not '1504'
                "month": [11],
                "day": [15]
            ]
        )

        // Test various date formats
        let dateFormats = [
            (1, 1, 1999),
            (11, 8, 2000),
            (9, 12, 2005),
            (22, 11, 1551)
        ]
        for (day, month, year) in dateFormats {
            let passwordWithoutSeparator = "\(year)\(month)\(day)"
            let matches = matching.dateMatch(password: passwordWithoutSeparator, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches \(passwordWithoutSeparator)"
            checkMatches(
                msg,
                matches,
                "date",
                [passwordWithoutSeparator],
                [(0, passwordWithoutSeparator.count - 1)],
                [
                    "separator": [""],
                    "year": [year]
                ]
            )

            let passwordWithSeparator = "\(year).\(month).\(day)"
            let matches2 = matching.dateMatch(password: passwordWithSeparator, rankedDictionaries: matching.rankedDictionaries)
            let msg2 = "matches \(passwordWithSeparator)"
            checkMatches(
                msg2,
                matches2,
                "date",
                [passwordWithSeparator],
                [(0, passwordWithSeparator.count - 1)],
                [
                    "separator": ["."],
                    "year": [year]
                ]
            )
        }

        // Test zero-padded dates
        let zeroPaddedPassword = "02/02/02"
        let matches2 = matching.dateMatch(password: zeroPaddedPassword, rankedDictionaries: matching.rankedDictionaries)
        let msg2 = "matches zero-padded dates"
        checkMatches(
            msg2,
            matches2,
            "date",
            [zeroPaddedPassword],
            [(0, zeroPaddedPassword.count - 1)],
            [
                "separator": ["/"],
                "year": [2002],
                "month": [2],
                "day": [2]
            ]
        )

        // Test embedded dates
        let prefixes = ["a", "ab"]
        let suffixes = ["!"]
        let pattern = "1/1/91"
        for (password, i, j) in genpws(pattern: pattern, prefixes: prefixes, suffixes: suffixes) {
            let matches = matching.dateMatch(password: password, rankedDictionaries: matching.rankedDictionaries)
            let msg = "matches embedded dates"
            checkMatches(
                msg,
                matches,
                "date",
                [pattern],
                [(i, j)],
                [
                    "year": [1991],
                    "month": [1],
                    "day": [1]
                ]
            )
        }

        // Test overlapping dates
        let overlapPassword = "12/20/1991.12.20"
        let matches3 = matching.dateMatch(password: overlapPassword, rankedDictionaries: matching.rankedDictionaries)
        let msg3 = "matches overlapping dates"
        checkMatches(
            msg3,
            matches3,
            "date",
            ["12/20/1991", "1991.12.20"],
            [(0, 9), (6, 15)],
            [
                "separator": ["/", "."],
                "year": [1991, 1991],
                "month": [12, 12],
                "day": [20, 20]
            ]
        )

        // Test dates padded by non-ambiguous digits
        let paddedPassword = "912/20/919"
        let matches4 = matching.dateMatch(password: paddedPassword, rankedDictionaries: matching.rankedDictionaries)
        let msg4 = "matches dates padded by non-ambiguous digits"
        checkMatches(
            msg4,
            matches4,
            "date",
            ["12/20/91"],
            [(1, 8)],
            [
                "separator": ["/"],
                "year": [1991],
                "month": [12],
                "day": [20]
            ]
        )
    }

    func testOmnimatch() {
        XCTAssertTrue(matching.omnimatch(password: "") == [], "Doesn't match ''")

        let password = "r0sebudmaelstrom11/20/91aaaa"
        let matches = matching.omnimatch(password: password)

        let testCases: [(String, (Int, Int))] = [
            ("dictionary", (0, 6)),
            ("dictionary", (7, 15)),
            ("date", (16, 23)),
            ("repeat", (24, 27))
        ]

        for (patternName, (i, j)) in testCases {
            var included = false
            for match in matches {
                if match.i == i && match.j == j && match.pattern == match.pattern {
                    included = true
                }
            }
            let msg = "for \(password), matches a \(patternName) pattern at (\(i), \(j))"
            XCTAssertTrue(included, msg)
        }
    }
}
