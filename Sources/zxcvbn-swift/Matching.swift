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

    func omnimatch(password: String, rankedDictionaries: [String: [String: Int]]? = nil) -> [Match] {
        let rankedDictionaries = rankedDictionaries ?? self.rankedDictionaries
        var matches: [Match] = []
        let matchers: [(String, [String: [String: Int]]) -> [Match]] = [
            dictionaryMatch,
            reverseDictionaryMatch,
            repeatMatch,
            sequenceMatch,
            regexMatch,
            dateMatch
        ]

        for matcher in matchers {
            matches.append(contentsOf: matcher(password, rankedDictionaries))
        }
        matches.append(contentsOf: spatialMatch(password: password, rankedDictionaries: rankedDictionaries))
        matches.append(contentsOf: l33tMatch(password: password, rankedDictionaries: rankedDictionaries))

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

            // Swap i and j before adjusting for the reversed string
            let temp = match.i
            match.i = match.j
            match.j = temp

            // Adjust i and j for the reversed string
            match.i = password.count - 1 - match.i
            match.j = password.count - 1 - match.j
        }

        matches.sort { ($0.i, $0.j) < ($1.i, $1.j) }
        return matches
    }

    func l33tMatch(password: String, rankedDictionaries: [String: [String: Int]], table: [Character: [Character]] = MatchingHelpers.shared.l33tTable) -> [Match] {
        var matches: [Match] = []

        let relevantSubtable = matchingHelpers.relevantL33tSubtable(password: password, table: table)
        let l33tSubs = matchingHelpers.enumerateL33tSubs(table: relevantSubtable)

        for sub in l33tSubs {
            if sub.isEmpty {
                continue
            }

            let subbedPassword = matchingHelpers.translate(password, chrMap: sub)

            for match in dictionaryMatch(password: subbedPassword, rankedDictionaries: rankedDictionaries) {
                let matchTokens = matches.map { $0.token }
                let startIndex = password.index(password.startIndex, offsetBy: match.i)
                let endIndex = password.index(password.startIndex, offsetBy: match.j)
                let token = String(password[startIndex...endIndex])
                if token.lowercased() == match.matchedWord || matchTokens.contains(token) {
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
        var lastPos = 0

        while lastPos < password.count {
            let greedyMatch = greedyPattern?.firstMatch(
                in: password,
                range: NSRange(
                    location: lastPos,
                    length: password.count - lastPos
                )
            )
            let lazyMatch = lazyPattern?.firstMatch(
                in: password,
                range: NSRange(
                    location: lastPos,
                    length: password.count - lastPos
                )
            )

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

            let i = matchRange.lowerBound.utf16Offset(in: password)
            let j = matchRange.upperBound.utf16Offset(in: password) - 1
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
            
            lastPos = j + 1
        }

        return matches
    }

    func spatialMatch(password: String, graphs: [String: [String: [String?]]]? = nil, rankedDictionaries: [String: [String: Int]]) -> [Match] {
        let graphs = graphs ?? self.graphs
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
        
        var i = 0
        var lastDelta: Int? = nil
        
        for k in 1..<password.count {
            let delta = Int(password.unicodeScalars[password.index(password.startIndex, offsetBy: k)].value) - Int(password.unicodeScalars[password.index(password.startIndex, offsetBy: k - 1)].value)

            if lastDelta == nil {
                lastDelta = Int(delta)
            }

            if let lastDelta, delta == lastDelta {
                continue
            }

            let j = k - 1
//            let j = password.index(password.startIndex, offsetBy: k - 1)
            matchingHelpers.update(password: password, i: i, j: j, delta: lastDelta!, result: &result)
//            i = password.index(after: j)
            i = j
            lastDelta = Int(delta)
        }
        
        matchingHelpers.update(password: password, i: i, j: password.count - 1, delta: lastDelta ?? 0, result: &result)
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

                guard let maybeDateNoSeparatorPattern = maybeDateNoSeparatorPattern, 
                        maybeDateNoSeparatorPattern.numberOfMatches(
                            in: token,
                            options: [],
                            range: NSRange(location: 0, length: token.count)
                        ) > 0 else { continue }

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

                if candidates.isEmpty {
                    continue
                }

                func metric(_ candidate: DateComponents) -> Int {
                    guard let year = candidate.year else { return 0 }
                    return abs(year - matchingHelpers.referenceYear)
                }

                var bestCandidate = candidates[0]
                var minDistance = metric(bestCandidate)

                for candidate in candidates.dropFirst() {
                    let distance = metric(candidate)
                    if distance < minDistance {
                        bestCandidate = candidate
                        minDistance = distance
                    }
                }

                let match = Match(i: i, j: j, token: token)
                match.pattern = "date"
                match.separator = ""
                match.year = bestCandidate.year
                match.month = bestCandidate.month
                match.day = bestCandidate.day
                matches.append(match)
            }
        }

        // Dates with separators (length 6 to 10)
        if password.count > 5 {
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
        }

        // Remove date matches that are strict substrings of others
        return matches.filter { match in
            !matches.contains { otherMatch in
                otherMatch.i <= match.i && otherMatch.j >= match.j && otherMatch != match
            }
        }.sorted { $0.i == $1.i ? $0.j < $1.j : $0.i < $1.i }
    }
}
