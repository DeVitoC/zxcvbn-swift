//
//  TestMatchingHelpers.swift
//  
//
//  Created by Christopher DeVito on 3/9/24.
//

import XCTest
@testable import zxcvbn_swift

final class TestMatchingHelpers: XCTestCase {
    let matchingHelpers = MatchingHelpers.shared

    func testAddFrequencyLists() {
        let rankedDictionaries = matchingHelpers.addFrequencyLists(frequencyLists: ["test_words": ["qidkviflkdoejjfkd", "sjdshfidssdkdjdhfkl"]])

        XCTAssertTrue(rankedDictionaries.keys.contains("test_words"))
        XCTAssertEqual(rankedDictionaries["test_words"], ["qidkviflkdoejjfkd": 1, "sjdshfidssdkdjdhfkl": 2])
    }

    func testMatchingUtils() {
        let chrMap: [Character: Character] = ["a": "A", "b": "B"]

        let testCases = [
            ("a", chrMap, "A"),
            ("c", chrMap, "c"),
            ("ab", chrMap, "AB"),
            ("abc", chrMap, "ABc"),
            ("aa", chrMap, "AA"),
            ("abab", chrMap, "ABAB"),
            ("", chrMap, ""),
            ("", [:], ""),
            ("abc", [:], "abc")
        ]

        for (string, map, result) in testCases {
            XCTAssertEqual(matchingHelpers.translate(string, chrMap: map), result, "translates '\(string)' to '\(result)' with provided charmap")
        }
    }
}
