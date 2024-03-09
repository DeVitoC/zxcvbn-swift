//
//  Matching.swift
//
//
//  Created by Christopher DeVito on 3/8/24.
//

import Foundation

class Matching {
    let matchingHelpers = MatchingHelpers.shared
    let graphs: [String: [String: [String?]]]
    let rankedDictionaries: [String: [String: Int]]
    var regexn: [String: NSRegularExpression] = [:]
    let dateMaxYear = 2050
    let dateMinYear = 1000

    init() {
        let frequencyList = Helpers.shared.loadFrequencyLists()
        graphs = Helpers.shared.loadAdjacencyGraphs()
        rankedDictionaries = matchingHelpers.addFrequencyLists(frequencyLists: frequencyList)
        do {
            let recentYearRegex = try NSRegularExpression(pattern: "19\\d\\d|200\\d|201\\d", options: [])
            regexn["recentYear"] = recentYearRegex
        } catch {
            print("Error creating recentYearRegex: \(error)")
        }
    }

    func omnimatch(password: String ) -> [Match] {
        var matches: [Match] = []
        let matchers: [(String, [String: [String: Int]]) -> [Match]] = [
            dictionaryMatch,
            reverseDictionaryMatch,
            l33tMatch,
//            spatialMatch,
            repeatMatch,
//            sequenceMatch,
//            regexMatch,
//            dateMatch
        ]

        for matcher in matchers {
            matches.append(contentsOf: matcher(password, rankedDictionaries))
        }

        matches.sort { $0.i < $1.i || ($0.i == $1.i && $0.j < $1.j) }
        return matches
    }

    func dictionaryMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        var matches: [Match] = []
        let length = password.count
        let passwordLower = password.lowercased()
        
        for (dictionaryName, rankedDict) in rankedDictionaries {
            for i in 0..<length {
                for j in i..<length {
                    let range = passwordLower.index(passwordLower.startIndex, offsetBy: i)...passwordLower.index(passwordLower.startIndex, offsetBy: j)
                    let word = String(passwordLower[range])
                    let token = String(password[range])
                    if let rank = rankedDict[word] {
                        let match = Match(i: i, j: j, token: token)
                        match.pattern = "dictionary"
                        match.matchedWord = word
                        match.rank = Double(rank)
                        match.dictionaryName = dictionaryName
                        match.reversed = false
                        match.l33t = false
                        matches.append(match)
                    }
                }
            }
            matches.sort { ($0.i, $0.j) < ($1.i, $1.j) }
        }
        return matches
    }

    func reverseDictionaryMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        let reversedPassword = String(password.reversed())
        var matches = dictionaryMatch(password: reversedPassword, rankedDictionaries: rankedDictionaries)
        for match in matches {
            match.token = String(match.token.reversed())
            match.reversed = true
            match.i = password.count - 1 - match.j
            match.j = password.count - 1 - match.i
        }

        matches.sort { ($0.i, $0.j) < ($1.i, $1.j)}
        return matches
    }

    func l33tMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        var matches: [Match] = []

        let relevantSubtable = matchingHelpers.relevantL33tSubtable(password: password, table: matchingHelpers.l33tTable)
        let l33tSubs = matchingHelpers.enumerateL33tSubs(table: relevantSubtable)

        for sub in l33tSubs {
            if sub.isEmpty {
                break
            }

            let subbedPassword = matchingHelpers.translate(password, chrMap: sub)

            for match in dictionaryMatch(password: subbedPassword, rankedDictionaries: rankedDictionaries) {
                let startIndex = password.index(password.startIndex, offsetBy: match.i)
                let endIndex = password.index(password.startIndex, offsetBy: match.j)
                let token = String(password[startIndex...endIndex])
                if token.lowercased() == match.matchedWord {
                    continue
                }

                var matchSub: [Character: Character] = [:]
                for (subbedChr, chr) in sub {
                    if token.contains(subbedChr) {
                        matchSub[subbedChr] = chr
                    }
                }

                if !matchSub.isEmpty {
                    let matchDict = match
                    matchDict.l33t = true
                    matchDict.token = token
                    matchDict.sub = matchSub
                    matchDict.subDisplay = matchSub.map { "\($0.0) -> \($0.1)" }.joined(separator: ", ")
                    matches.append(matchDict)
                }
            }
        }

        matches = matches.filter { $0.token.count > 1 }
        return matches.sorted { (match1, match2) -> Bool in
            let i1 = match1.i
            let j1 = match1.j
            let i2 = match2.i
            let j2 = match2.j
            return (i1, j1) < (i2, j2)
        }
    }

    func repeatMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        let greedyPattern = try? NSRegularExpression(pattern: "(.+)\\1+", options: [])
        let lazyPattern = try? NSRegularExpression(pattern: "(.+?)\\1+", options: [])
        let lazyAnchoredPattern = try? NSRegularExpression(pattern: "^(.+?)\\1+$", options: [])

        var matches: [Match] = []
        var lastIndex = password.startIndex

        while lastIndex < password.endIndex {
            let greedyMatch = greedyPattern?.firstMatch(in: password, options: [], range: NSRange(location: password.distance(from: password.startIndex, to: lastIndex), length: password.count - password.distance(from: password.startIndex, to: lastIndex)))
            let lazyMatch = lazyPattern?.firstMatch(in: password, options: [], range: NSRange(location: password.distance(from: password.startIndex, to: lastIndex), length: password.count - password.distance(from: password.startIndex, to: lastIndex)))

            if greedyMatch == nil {
                break
            }

            let greedyMatchRange = Range(greedyMatch!.range, in: password)!
            let greedyMatchString = String(password[greedyMatchRange])

            let lazyMatchRange = Range(lazyMatch!.range, in: password)!
            let lazyMatchString = String(password[lazyMatchRange])

            var matchRange: Range<String.Index>
            var baseToken: String

            if greedyMatchString.count > lazyMatchString.count {
                matchRange = greedyMatchRange
                let lazyAnchoredMatch = lazyAnchoredPattern?.firstMatch(in: greedyMatchString, options: [], range: NSRange(location: 0, length: greedyMatchString.count))
                let lazyAnchoredMatchRange = Range(lazyAnchoredMatch!.range(at: 1), in: greedyMatchString)!
                baseToken = String(greedyMatchString[lazyAnchoredMatchRange])
            } else {
                matchRange = lazyMatchRange
                let lazyMatchRange = Range(lazyMatch!.range(at: 1), in: password)!
                baseToken = String(password[lazyMatchRange])
            }

            let i = password.distance(from: password.startIndex, to: matchRange.lowerBound)
            let j = password.distance(from: password.startIndex, to: matchRange.upperBound) - 1
            let token = String(password[matchRange])
            
            let omniMatchResult = omnimatch(password: baseToken)
            let baseAnalysis = Scoring().mostGuessableMatchSequence(password: baseToken, matches: omniMatchResult)
            let baseMatches = baseAnalysis.sequence
            let baseGuesses = baseAnalysis.guesses

            let repeatCount = Double(token.count) / Double(baseToken.count)
            
            let match = Match(i: i, j: j, token: token)
            match.pattern = "repeat"
            match.baseToken = baseToken
            match.baseGuesses = baseGuesses
            match.baseMatches = baseMatches
            match.repeatCount = repeatCount
            
            matches.append(match)

            lastIndex = password.index(after: password.index(password.startIndex, offsetBy: j + 1))
        }

        return matches
    }
}

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
    let dateSplits: [Int: [[Int]]] = [
        4: [[1, 2], [2, 3]],
        5: [[1, 3], [2, 3]],
        6: [[1, 2], [2, 4], [4, 5]],
        7: [[1, 3], [2, 3], [4, 5], [4, 6]],
        8: [[2, 4], [4, 6]]
    ]
    var rankedDictionaries: [String: [String: Int]] = [:]

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
            let assoc = sub.map { ($1, $0) }.sorted { $0.0 < $1.0 }
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
                } else {
                    var subExtension = sub
                    subExtension.append((l33tChar, firstKey))
                    nextSubs.append(subExtension)
                }
                nextSubs.append(sub)
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
}


