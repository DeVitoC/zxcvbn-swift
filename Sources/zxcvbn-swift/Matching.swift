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
            spatialMatch,
            repeatMatch,
            sequenceMatch,
            regexMatch,
            dateMatch
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

    func spatialMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        var matches: [Match] = []
        for (graphName, graph) in graphs {
            let spatialMatchHelper = matchingHelpers.spatialMatchHelper(password: password, graph: graph, graphName: graphName)
            matches.append(contentsOf: spatialMatchHelper)
        }
        return matches.sorted { (match1, match2) -> Bool in
            let i1 = match1.i
            let j1 = match1.j
            let i2 = match2.i
            let j2 = match2.j
            return (i1, j1) < (i2, j2)
        }
    }

    func sequenceMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        guard password.count > 1 else { return [] }
        
        var result: [Match] = []

        var i = password.startIndex
        var lastDelta: Int? = nil
        
        for k in 1..<password.count {
            let delta = Int(password.unicodeScalars[password.index(password.startIndex, offsetBy: k)].value) - Int(password.unicodeScalars[password.index(password.startIndex, offsetBy: k - 1)].value)

            if lastDelta == nil {
                lastDelta = Int(delta)
            }
            
            if let lastDelta, delta == lastDelta {
                continue
            }
            
            let j = password.index(password.startIndex, offsetBy: k - 1)
            matchingHelpers.update(password: password, i: i, j: j, delta: lastDelta!, result: &result)
            i = password.index(after: j)
            lastDelta = Int(delta)
        }
        
        matchingHelpers.update(password: password, i: i, j: password.endIndex, delta: lastDelta ?? 0, result: &result)
        return result
    }

    func regexMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        var matches: [Match] = []
        
        for (name, regex) in regexn {
            let results = regex.matches(in: password, options: [], range: NSRange(location: 0, length: password.count))
            for result in results {
                let range = Range(result.range, in: password)!
                let token = String(password[range])
                let match = Match(i: password.distance(from: password.startIndex, to: range.lowerBound), 
                                  j: password.distance(from: password.startIndex, to: range.upperBound) - 1,
                                  token: token)
                match.pattern = "regex"
                match.regexName = name
                var capturedGroups: [String] = []
                for range in 0..<result.numberOfRanges {
                    let capturedRange = result.range(at: range)
                    let range = capturedRange
                    let capturedGroup = String(password[Range(range, in: password)!])
                    capturedGroups.append(capturedGroup)
                }
                match.regexMatch = capturedGroups
                matches.append(match)
            }
        }
        
        return matches.sorted { (match1, match2) -> Bool in
            let i1 = match1.i
            let j1 = match1.j
            let i2 = match2.i
            let j2 = match2.j
            return (i1, j1) < (i2, j2)
        }
    }

    func dateMatch(password: String, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        let maybeDateNoSeparatorPattern = try? NSRegularExpression(pattern: "^\\d{4,8}$")
        let maybeDateWithSeparatorPattern = try? NSRegularExpression(pattern: "^(\\d{1,4})([\\s/\\\\_.\\-])(\\d{1,2})\\2(\\d{1,4})$")

        var matches: [Match] = []

        // Dates without separators (length 4 to 8)
        guard password.count > 3 else { return matches }
        for i in 0..<(password.count - 3) {
            for j in (i + 3)..<min(i + 8, password.count) {
                let token = String(password[password.index(password.startIndex, offsetBy: i)..<password.index(password.startIndex, offsetBy: j + 1)])
                if let maybeDateNoSeparatorPattern = maybeDateNoSeparatorPattern,
                   maybeDateNoSeparatorPattern.numberOfMatches(in: token, options: [], range: NSRange(location: 0, length: token.count)) > 0 {
                    var candidates: [DateComponents] = []
                    for (k, l) in matchingHelpers.dateSplits[token.count] ?? [] {
                        let startToK = Int(token[token.startIndex..<token.index(token.startIndex, offsetBy: k)]) ?? 0
                        let kTo1 = Int(token[token.index(token.startIndex, offsetBy: k)..<token.index(token.startIndex, offsetBy: l)]) ?? 0
                        let tokenMinusFirst = Int(token[token.index(token.startIndex, offsetBy: l)..<token.endIndex]) ?? 0
                        if let dmy = matchingHelpers.mapIntsToDateComponents([
                            startToK,
                            kTo1,
                            tokenMinusFirst
                        ]) {
                            candidates.append(dmy)
                        }
                    }

                    if !candidates.isEmpty {
                        let bestCandidate = candidates.min(by: { abs($0.year ?? 0 - matchingHelpers.referenceYear) < abs($1.year ?? 0 - matchingHelpers.referenceYear) })
                        if let bestCandidate = bestCandidate {
                            let match = Match(i: i, j: j, token: token)
                            match.pattern = "date"
                            match.separator = nil
                            match.year = bestCandidate.year
                            match.month = bestCandidate.month
                            match.day = bestCandidate.day
                            matches.append(match)
                        }
                    }
                }
            }
        }

        // Dates with separators (length 6 to 10)
        for i in 0..<(password.count - 5) {
            for j in (i + 5)..<min(i + 10, password.count) {
                let token = String(password[password.index(password.startIndex, offsetBy: i)..<password.index(password.startIndex, offsetBy: j + 1)])
                if let maybeDateWithSeparatorPattern = maybeDateWithSeparatorPattern,
                   let match = maybeDateWithSeparatorPattern.firstMatch(in: token, options: [], range: NSRange(location: 0, length: token.count)),
                   let dmy = matchingHelpers.mapIntsToDateComponents([
                    Int(token[Range(match.range(at: 1), in: token)!]) ?? 0,
                    Int(token[Range(match.range(at: 3), in: token)!]) ?? 0,
                    Int(token[Range(match.range(at: 4), in: token)!]) ?? 0
                   ]) {
                    let separator = String(token[Range(match.range(at: 2), in: token)!])
                    let newMatch = Match(i: i, j: j, token: token)
                    newMatch.pattern = "date"
                    newMatch.separator = separator
                    newMatch.year = dmy.year
                    newMatch.month = dmy.month
                    newMatch.day = dmy.day
                    matches.append(newMatch)
                }
            }
        }

        // Remove date matches that are strict substrings of others
        return matches.filter { match in
            !matches.contains { otherMatch in
                otherMatch.i <= match.i && otherMatch.j >= match.j && otherMatch != match
            }
        }.sorted { $0.i == $1.i ? $0.j < $1.j : $0.i < $1.i }
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
    let dateSplits: [Int: [(Int, Int)]] = [
        4: [(1, 2), (2, 3)],
        5: [(1, 3), (2, 3)],
        6: [(1, 2), (2, 4), (4, 5)],
        7: [(1, 3), (2, 3), (4, 5), (4, 6)],
        8: [(2, 4), (4, 6)]
    ]
    private var rankedDictionaries: [String: [String: Int]] = [:]
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

    func spatialMatchHelper(password: String, graph: [String: [String?]], graphName: String) -> [Match] {
        var matches: [Match] = []
        var i = password.startIndex

        while i < password.index(password.endIndex, offsetBy: -1) {
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

    func update(password: String, i: String.Index, j: String.Index, delta: Int, result: inout [Match]) {
        let distance = password.distance(from: i, to: j)
        if distance > 1 || (delta != 0 && abs(delta) == 1) {
            if abs(delta) <= maxDelta {
                let token = String(password[i..<j])
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

                let match = Match(i: password.distance(from: password.startIndex, to: i), j: password.distance(from: password.startIndex, to: j), token: token)
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
