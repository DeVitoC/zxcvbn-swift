//
//  MatchingHelpers.swift
//
//
//  Created by Christopher DeVito on 3/9/24.
//

import Foundation

class MatchingHelpers {
    static var shared = MatchingHelpers()
    let l33tTable: [Character: [Character]] = [
        "a": ["4", "@"],
        "b": ["8"],
        "c": ["(", "{", "[", "<"],
        "e": ["3"],
        "g": ["6", "9"],
        "i": ["1", "!", "|"],
        "l": ["1", "|", "7"],
        "o": ["0"],
        "s": ["$", "5"],
        "t": ["7", "+"],
        "x": ["%"],
        "z": ["2"]
    ]
    let dateSplits: [Int: [(Int, Int)]] = [
        4: [(1, 2), (2, 3)],
        5: [(1, 3), (2, 3)],
        6: [(1, 2), (2, 4), (4, 5)],
        7: [(1, 3), (2, 3), (4, 5), (4, 6)],
        8: [(2, 4), (4, 6)]
    ]
    private let shiftedPattern = try? NSRegularExpression(pattern: "[~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?]", options: [])
    private let maxDelta: Int = 5
    let referenceYear = Calendar.current.component(.year, from: Date())
    private let dateMinYear = 1000
    private let dateMaxYear = 2099


    func addFrequencyLists(frequencyLists: [String: [String]]) -> [String: [String: Int]] {
        var rankedDict: [String: [String: Int]] = [:]
        for (name, list) in frequencyLists {
            rankedDict[name] = Helpers.shared.buildRankedDict(list)
        }

        return rankedDict
    }

    func relevantL33tSubtable(password: String, table: [Character: [Character]]) -> [Character: [Character]] {
        let passwordChars = Set(password)
        var subtable: [Character: [Character]] = [:]

        for (letter, subs) in table {
            let relevantSubs = subs.filter { passwordChars.contains($0) }
            if !relevantSubs.isEmpty {
                subtable[letter] = relevantSubs
            }
        }

        return subtable
    }

    private func dedup(_ subs: [[(Character, Character)]]) -> [[(Character, Character)]] {
        var deduped: [[(Character, Character)]] = []
        var members: [String: Bool] = [:]

        for sub in subs {
            let assoc = sub.map { ($1, $0) }.sorted { $0.0 > $1.0 }
            let label = assoc.map { "\($0.0),\($0.1)" }.joined(separator: "-")
            if members[label] == nil {
                members[label] = true
                deduped.append(sub)
            }
        }
        return deduped
    }

    private func generateSubstitutions(keys: [Character], subs: [[(Character, Character)]], table: [Character: [Character]]) -> [[(Character, Character)]] {
        guard let firstKey = keys.first else {
            return subs
        }

        let restKeys = Array(keys.dropFirst())
        var nextSubs: [[(Character, Character)]] = [[]]

        for l33tChar in table[firstKey] ?? [] {
            for sub in subs {
                if let dupL33tIndex = sub.firstIndex(where: { $0.0 == l33tChar }) {
                    var subAlternative = sub
                    subAlternative.remove(at: dupL33tIndex)
                    subAlternative.append((l33tChar, firstKey))
                    nextSubs.append(subAlternative)
                    nextSubs.append(sub)
                } else {
                    var subExtension = sub
                    subExtension.append((l33tChar, firstKey))
                    nextSubs.append(subExtension)
                }
            }
        }
        let dedupedSubs = dedup(nextSubs)
        return generateSubstitutions(keys: restKeys, subs: dedupedSubs, table: table)
    }

    func enumerateL33tSubs(table: [Character: [Character]]) -> [[Character: Character]] {
        let keys = Array(table.keys)
        let subs: [[(Character, Character)]] = [[]]

        let subsWithAssocs = generateSubstitutions(keys: keys, subs: subs, table: table)
        let subDicts = subsWithAssocs.map { assocs in
            var subDict: [Character: Character] = [:]
            for assoc in assocs {
                subDict[assoc.0] = assoc.1
            }
            return subDict
        }
        return subDicts
    }

    func translate(_ string: String, chrMap: [Character: Character]) -> String {
        var chars: [Character] = []
        for char in string {
            if let substitution = chrMap[char] {
                chars.append(substitution)
            } else {
                chars.append(char)
            }
        }
        return String(chars)
    }

    func spatialMatchHelper(password: String, graph: [String: [String?]], graphName: String) -> [Match] {
        var matches: [Match] = []
        var i = password.startIndex

        guard password.count > 0 else { return matches }

        while i < password.index(password.startIndex, offsetBy: password.count - 1) {
            var j = password.index(after: i)
            var lastDirection: Int? = nil
            var turns = 0

            var shiftedCount = 0

            if ["qwerty", "dvorak"].contains(graphName) {
                if i < password.endIndex {
                    let range = NSRange(location: password.distance(from: password.startIndex, to: i), length: 1)
                    if let _ = shiftedPattern?.firstMatch(in: password, options: [], range: range) {
                        shiftedCount = 1
                    }
                }
            }

            while true {
                let prevChar = password[password.index(before: j)]
                var found = false
                var foundDirection = -1
                var curDirection = -1

                let adjacents = graph[String(prevChar)] ?? []

                if j < password.endIndex {
                    let curChar = password[j]
                    for adj in adjacents {
                        curDirection += 1
                        guard let adj else { continue }
                        if adj.contains(curChar) {
                            found = true
                            foundDirection = curDirection
                            if adj.firstIndex(of: curChar) == adj.index(adj.startIndex, offsetBy: 1) {
                                shiftedCount += 1
                            }
                            if lastDirection != foundDirection {
                                turns += 1
                                lastDirection = foundDirection
                            }
                            break
                        }
                    }
                }

                if found {
                    j = password.index(after: j)
                } else {
                    if password.distance(from: i, to: j) > 2 {
                        let token = String(password[i..<j])
                        let match = Match(i: password.distance(from: password.startIndex, to: i), j: password.distance(from: password.startIndex, to: j) - 1, token: token)
                        match.pattern = "spatial"
                        match.graph = graphName
                        match.turns = turns
                        match.shiftedCount = shiftedCount
                        matches.append(match)
                    }
                    i = j
                    break
                }
            }
        }

        return matches
    }

    func update(password: String, i: Int, j: Int, delta: Int, result: inout [Match]) {
        let iIndex = password.index(password.startIndex, offsetBy: i)
        let jIndex = password.index(password.startIndex, offsetBy: j)
//        let distance = password.distance(from: iIndex, to: jIndex)
        let distance = j - i
        if distance > 1 || (delta != 0 && abs(delta) == 1) {
            if abs(delta) <= maxDelta {
                let token = String(password[iIndex...jIndex])
                let sequenceName: String
                let sequenceSpace: Int

                if let _ = token.range(of: "^[a-z]+$", options: .regularExpression) {
                    sequenceName = "lower"
                    sequenceSpace = 26
                } else if let _ = token.range(of: "^[A-Z]+$", options: .regularExpression) {
                    sequenceName = "upper"
                    sequenceSpace = 26
                } else if let _ = token.range(of: "^\\d+$", options: .regularExpression) {
                    sequenceName = "digits"
                    sequenceSpace = 10
                } else {
                    sequenceName = "unicode"
                    sequenceSpace = 26
                }

                let match = Match(i: i, j: j, token: token)
                match.pattern = "sequence"
                match.sequenceName = sequenceName
                match.sequenceSpace = sequenceSpace
                match.ascending = delta > 0
                result.append(match)
            }
        }
    }

    func mapIntsToDateComponents(_ ints: [Int]) -> DateComponents? {
        // Validate the input
        if ints.count != 3 {
            return nil
        }

        var overTwelve = 0
        var overThirtyOne = 0
        var underOne = 0

        for int in ints {
            if int > 31 {
                overThirtyOne += 1
            }
            if int > 12 {
                overTwelve += 1
            }
            if int <= 0 {
                underOne += 1
            }
            if 99 < int && int < dateMinYear || int > dateMaxYear {
                return nil
            }
        }

        if ints[1] > 31 || ints[1] <= 0 || overThirtyOne >= 2 || overTwelve == 3 || underOne >= 2 {
            return nil
        }

        // Look for a four-digit year
        let possibleFourDigitSplits = [(ints[2], [ints[0], ints[1]]), (ints[0], [ints[1], ints[2]])]
        for (year, rest) in possibleFourDigitSplits {
            if dateMinYear <= year && year <= dateMaxYear {
                if let dm = mapIntsToDateMonth(rest) {
                    return DateComponents(year: year, month: dm.month, day: dm.day)
                }
            }
        }

        // No four-digit year, try two-digit years
        for (year, rest) in possibleFourDigitSplits {
            if let dm = mapIntsToDateMonth(rest), let fourDigitYear = twoToFourDigitYear(year) {
                return DateComponents(year: fourDigitYear, month: dm.month, day: dm.day)
            }
        }

        return nil
    }

    private func mapIntsToDateMonth(_ ints: [Int]) -> DateComponents? {
        for (day, month) in [(ints[0], ints[1]), (ints[1], ints[0])] {
            if 1 <= day && day <= 31 && 1 <= month && month <= 12 {
                return DateComponents(month: month, day: day)
            }
        }
        return nil
    }

    private func twoToFourDigitYear(_ year: Int) -> Int? {
        if year > 99 {
            return year
        } else if year > 50 {
            return year + 1900 // 87 -> 1987
        } else {
            return year + 2000 // 15 -> 2015
        }
    }
}
