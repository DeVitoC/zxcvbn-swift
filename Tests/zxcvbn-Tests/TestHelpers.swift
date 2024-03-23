//
//  TestHelpers.swift
//  
//
//  Created by Christopher DeVito on 3/9/24.
//

import XCTest
@testable import zxcvbn

final class TestHelpers: XCTestCase {
    let helpers = Helpers.shared

    func testLoadAdjacencyGraphs() {
        let graphs = helpers.loadAdjacencyGraphs()
        XCTAssertFalse(graphs.isEmpty)
        XCTAssertTrue(graphs["qwerty"] != nil)
        XCTAssertTrue(graphs["dvorak"] != nil)
        XCTAssertTrue(graphs["mac_keypad"] != nil)
        XCTAssertTrue(graphs["keypad"] != nil)
        let qwerty = graphs["qwerty"] ?? [:]
        XCTAssertTrue(qwerty[String("$")] == ["3#",nil,nil,"5%","rR","eE"])
    }

    func testLoadFrequencyLists() {
        let lists = helpers.loadFrequencyLists()
        XCTAssertFalse(lists.isEmpty)
        XCTAssertTrue(lists["passwords"] != nil)
        XCTAssertTrue(lists["english_wikipedia"] != nil)
        XCTAssertTrue(lists["female_names"] != nil)
        XCTAssertTrue(lists["surnames"] != nil)
        XCTAssertTrue(lists["us_tv_and_film"] != nil)
        XCTAssertTrue(lists["male_names"] != nil)
        let passwords = lists["passwords"] ?? []
        XCTAssertTrue(passwords.contains("baseball"))
    }

    func testBuildRankedDict() {
        let list = ["a", "b", "c", "d", "e"]
        let ranked = helpers.buildRankedDict(list)
        XCTAssertEqual(ranked["a"], 1)
        XCTAssertEqual(ranked["b"], 2)
        XCTAssertEqual(ranked["c"], 3)
        XCTAssertEqual(ranked["d"], 4)
        XCTAssertEqual(ranked["e"], 5)
    }
}
