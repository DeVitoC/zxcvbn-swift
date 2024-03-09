////
////  Matcher.swift
////
////
////  Created by Christopher DeVito on 2/11/24.
////
//
//import Foundation
//
//class Matcher {
//    private var dictionaryMatchers: [MatcherBlock]
//    private var graphs: [String: [String: [String?]]]
//    private var matchers: [MatcherBlock] = []
//    var keyboardAverageDegree: Float = 0.0
//    var keypadAverageDegree: Float = 0.0
//    var keyboardStartingPositions: Int
//    var keypadStartingPositions: Int
//
//    init() {
//        let resources = MatchResources.shared
//        self.dictionaryMatchers = resources.dictionaryMatchers
//        self.graphs = resources.graphs
//        self.keyboardStartingPositions = graphs["qwerty"]?.count ?? 0
//        self.keypadStartingPositions = graphs["keypad"]?.count ?? 0
//        self.keyboardAverageDegree = calcAverageDegree(graphs["qwerty"] ?? [:])
//        self.keypadAverageDegree = calcAverageDegree(graphs["keypad"] ?? [:])
//        self.matchers = self.dictionaryMatchers + [
//            l33tMatch(),
//            digitsMatch(),
//            yearMatch(),
//            dateMatch(),
//            repeatMatch(),
//            sequenceMatch(),
//            spatialMatch()
//        ]
//    }
//
//
//    // MARK: - Matching Methods
//
//    func omnimatch(_ password: String, userInputs: [String]) -> [Match] {
//        if !userInputs.isEmpty {
//            var rankedUserInputsDict: [String: Int] = [:]
//            for (index, input) in userInputs.enumerated() {
//                rankedUserInputsDict[input.lowercased()] = index + 1
//            }
//            self.matchers.append(MatchResources.shared.buildDictMatcher("user_inputs", rankedDict: rankedUserInputsDict))
//        }
//
//        var matches: [Match] = []
//        for matcher in self.matchers {
//            matches.append(contentsOf: matcher(password))
//        }
//
//        return matches.sorted {
//            if $0.i != $1.i {
//                return $0.i < $1.i
//            } else {
//                return $0.j > $1.j
//            }
//        }
//    }
//
//    private func l33tMatch() -> (MatcherBlock) {
//        return { (password) in
//            var matches: [Match] = []
//
//            for sub in self.enumerateL33tSubs(self.relevantL33tSubtable(password: password)) {
//                if sub.isEmpty { break }
//                let subbedPassword = self.translate(password: password, characterMap: sub)
//
//                for matcher in self.dictionaryMatchers {
//                    let matcherMatches = matcher(subbedPassword)
//                    for index in matcherMatches.indices {
//                        let token = String(password[password.index(password.startIndex, offsetBy: matcherMatches[index].i)...password.index(password.startIndex, offsetBy: matcherMatches[index].j)])
//                        if token.lowercased() == matcherMatches[index].matchedWord {
//                            continue
//                        }
//
//                        var matchSub: [Character: Character] = [:]
//                        var subDisplay: [String] = []
//                        for (subbedChr, chr) in sub {
//                            if token.contains(subbedChr) {
//                                matchSub[Character(subbedChr)] = Character(chr)
//                                subDisplay.append("\(subbedChr) -> \(chr)")
//                            }
//                        }
//
//                        matcherMatches[index].l33t = true
//                        matcherMatches[index].token = token
//                        matcherMatches[index].sub = matchSub
//                        matcherMatches[index].subDisplay = subDisplay.joined(separator: ",")
//                    }
//                    matches.append(contentsOf: matcherMatches)
//                }
//            }
//
//            return matches
//        }
//    }
//
//    private func digitsMatch() -> MatcherBlock {
//        guard let digitsRegex = try? NSRegularExpression(pattern: "\\d{3,}", options: []) else { return { _ in [] } }
//
//        return { (password) in 
//            self.findAll(password: password, patternName: "digits", regex: digitsRegex)
//        }
//    }
//
//    private func yearMatch() -> MatcherBlock {
//        guard let yearRegex = try? NSRegularExpression(pattern: "19\\d\\d|200\\d|201\\d|202\\d", options: []) else { return { _ in [] } }
//
//        return { (password) in 
//            self.findAll(password: password, patternName: "year", regex: yearRegex)
//        }
//    }
//
//    private func dateMatch() -> MatcherBlock {
//        guard let dateRegex = try? NSRegularExpression(pattern: "(\\d{1,2})( |-|\\/|\\.|_)?(\\d{1,2})( |-|\\/|\\.|_)?(19\\d{2}|200\\d|201\\d|\\d{2})", options: []) else { return { _ in [] } }
//        
//        return { (password) in 
//            self.findAll(password: password, patternName: "date", regex: dateRegex)
//        }
//    }
//
//    private func repeatMatch() -> MatcherBlock {
//        return { (password) in 
//            var result: [Match] = []
//            var i = password.startIndex
//            while i < password.endIndex {
//                var j = password.index(after: i)
//                while true {
//                    let prevChar = password[i]
//                    let curChar = j < password.endIndex ? password[j] : nil
//                    if prevChar == curChar {
//                        j = password.index(after: j)
//                    } else {
//                        if password.distance(from: i, to: j) > 2 {
//                            let iMatch = password.distance(from: password.startIndex, to: i)
//                            let jMatch = password.distance(from: password.startIndex, to: j) - 1
//                            let tokenMatch = String(password[i..<j])
//                            let match = Match(i: iMatch, j: jMatch, token: tokenMatch)
//                            match.pattern = "repeat"
//                            match.repeatedChar = String(prevChar)
//                            result.append(match)
//                        }
//                        break
//                    }
//                }
//                i = j
//            }
//            return result
//        }
//    }
//
//    private func sequenceMatch() -> MatcherBlock {
//        let sequences = [
//            "lower": "abcdefghijklmnopqrstuvwxyz",
//            "upper": "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
//            "digits": "0123456789"
//        ]
//
//        return { (password) in 
//            var result: [Match] = []
//            var i = password.startIndex
//
//            while i < password.endIndex {
//                var j = password.index(after: i)
//                var seq: String? = nil
//                var seqName: String? = nil
//                var seqDirection: Int? = nil
//                
//                for (seqCandidateName, seqCandidate) in sequences {
//                    let iN = seqCandidate.distance(from: seqCandidate.startIndex, to: seqCandidate.firstIndex(of: password[i]) ?? seqCandidate.endIndex)
//                    let jN = j < password.endIndex ? seqCandidate.distance(from: seqCandidate.startIndex, to: seqCandidate.firstIndex(of: password[j]) ?? seqCandidate.endIndex) : nil
//                    if let jN, jN != seqCandidate.count && jN != seqCandidate.count {
//                        let direction = jN - iN
//                        if direction == 1 || direction == -1 {
//                            seq = seqCandidate
//                            seqName = seqCandidateName
//                            seqDirection = direction
//                            break
//                        }
//                    }
//                }
//                if let seq, let seqDirection {
//                    while true {
//                        let prevChar = password[password.index(before: j)]
//                        let curChar = j < password.endIndex ? password[j] : nil
//                        let prevN = seq.distance(from: seq.startIndex, to: seq.firstIndex(of: prevChar) ?? seq.endIndex)
//                        let curN = curChar != nil ? seq.distance(from: seq.startIndex, to: seq.firstIndex(of: curChar!) ?? seq.endIndex) : nil
//                        
//                        if let curN, curN - prevN == seqDirection {
//                            j = password.index(after: j)
//                        } else {
//                            if password.distance(from: i, to: j) > 2 {
//                                let iMatch = password.distance(from: password.startIndex, to: i)
//                                let jMatch = password.distance(from: password.startIndex, to: j) - 1
//                                let tokenMatch = String(password[i..<j])
//                                let match = Match(i: iMatch, j: jMatch, token: tokenMatch)
//                                match.pattern = "sequence"
//                                match.sequenceName = seqName ?? ""
//                                match.sequenceSpace = seq.count
//                                match.ascending = seqDirection == 1
//                                result.append(match)
//                            }
//                            break
//                        }
//                    }
//                }
//                i = j
//            }
//            
//            return result
//        }
//    }
//
//    private func spatialMatch() -> MatcherBlock {
//        return { (password) in
//            var matches: [Match] = []
//
//            for graphName in self.graphs.keys {
//                if let graph = self.graphs[graphName] {
//                    matches.append(contentsOf: self.spatialMatchHelper(password: password, graph: graph, graphName: graphName))
//                }
//            }
//
//            return matches
//        }
//    }
//
//    
//    // MARK: - Helper Methods
//
//    private func calcAverageDegree(_ graph: [String: [String?]]) -> Float {
//        var average: Float = 0.0
//        for key in graph.keys {
//            let neighbors = graph[key]?.filter { $0 != nil } ?? []
//            average += Float(neighbors.count)
//        }
//
//        average /= Float(graph.count)
//
//        return average
//    }
//
//    private func l33tTable() -> [String: [String]] {
//        return [
//            "a": ["4", "@"],
//            "b": ["8"],
//            "c": ["(", "{", "[", "<"],
//            "e": ["3"],
//            "g": ["6", "9"],
//            "i": ["1", "!", "|"],
//            "l": ["1", "|", "7"],
//            "o": ["0"],
//            "s": ["$", "5"],
//            "t": ["+", "7"],
//            "x": ["%"],
//            "z": ["2"]
//        ]
//    }
//
//    private func relevantL33tSubtable(password: String) -> [String: [String]] {
//        var filtered: [String: [String]] = [:]
//
//        for (letter, subs) in l33tTable() {
//            var relevantSubs: [String] = []
//            for sub in subs {
//                if password.contains(sub) {
//                    relevantSubs.append(sub)
//                }
//            }
//            if !relevantSubs.isEmpty {
//                filtered[letter] = relevantSubs
//            }
//        }
//
//        return filtered
//    }
//
//    private func enumerateL33tSubs(_ table: [String: [String]]) -> [[String: String]] {
//        var subs: [[(String, String)]] = [[]]
//
//        func dedup(_ subs: [[(String, String)]]) -> [[(String, String)]] {
//            var deduped = [[(String, String)]]()
//            var members = Set<String>()
//            for sub in subs {
//                let assoc = sub.sorted { $0.0.lowercased() < $1.0.lowercased() }
//                let label = assoc.map { "\($0.0),\($0.1)" }.joined(separator: "-")
//                if !members.contains(label) {
//                    members.insert(label)
//                    deduped.append(sub)
//                }
//            }
//            return deduped
//        }
//
//        var keys = Array(table.keys)
//
//        while !keys.isEmpty {
//            let firstKey = keys.removeFirst()
//            var nextSubs = [[(String, String)]]()
//
//            for l33tChr in table[firstKey] ?? [] {
//                for var sub in subs {
//                    if let dupL33tIndex = sub.firstIndex(where: { $0.0 == l33tChr }) {
//                        var subAlternative = sub
//                        subAlternative.remove(at: dupL33tIndex)
//                        subAlternative.append((l33tChr, firstKey))
//                        nextSubs.append(sub)
//                        nextSubs.append(subAlternative)
//                    } else {
//                        sub.append((l33tChr, firstKey))
//                        nextSubs.append(sub)
//                    }
//                }
//            }
//
//            subs = dedup(nextSubs)
//        }
//
//        return subs.map { sub in
//            var subDict = [String: String]()
//            for pair in sub {
//                subDict[pair.0] = pair.1
//            }
//            return subDict
//        }
//    }
//
//    private func translate(password: String, characterMap: [String: String]) -> String {
//        var translatedString = password
//        for (key, value) in characterMap {
//            translatedString = translatedString.replacingOccurrences(of: key, with: value)
//        }
//        return translatedString
//    }
//
//    func spatialMatchHelper(password: String, graph: [String: [String?]], graphName: String) -> [Match] {
//        var result: [Match] = []
//        
//        var i = password.startIndex
//        while i < password.index(before: password.endIndex) {
//            var j = password.index(after: i)
//            var lastDirection = -1
//            var turns = 0
//            var shiftedCount = 0
//            while true {
//                let prevChar = String(password[j])
//                var found = false
//                var foundDirection = -1
//                var curDirection = -1
//                let adjacents = graph[prevChar] ?? []
//                if j < password.endIndex {
//                    let curChar = String(password[j])
//                    for adj in adjacents {
//                        curDirection += 1
//                        if let adj, adj.contains(curChar) {
//                            found = true
//                            foundDirection = curDirection
//                            if adj.index(after: adj.startIndex) == adj.firstIndex(of: Character(curChar)){
//                                shiftedCount += 1
//                            }
//                            if lastDirection != foundDirection {
//                                turns += 1
//                                lastDirection = foundDirection
//                            }
//                            break
//                        }
//                    }
//                }
//                if found {
//                    j = password.index(after: j)
//                } else {
//                    if password.distance(from: i, to: j) > 2 {
//                        let iMatch = password.distance(from: password.startIndex, to: i)
//                        let jMatch = password.distance(from: password.startIndex, to: j) - 1
//                        let tokenMatch = String(password[i..<j])
//                        let match = Match(i: iMatch, j: jMatch, token: tokenMatch)
//                        match.pattern = "spatial"
//                        match.graph = graphName
//                        match.turns = turns
//                        match.shiftedCount = shiftedCount
//                        result.append(match)
//                    }
//                    i = j
//                    break
//                }
//            }
//        }
//
//        return result
//    }
//
//    func findAll(password: String, patternName: String, regex: NSRegularExpression) -> [Match] {
//        var matches: [Match] = []
//
//        let nsrange = NSRange(password.startIndex..<password.endIndex, in: password)
//        let results = regex.matches(in: password, options: [], range: nsrange)
//
//        for result in results {
//            let i = result.range.location
//            let j = result.range.length + i - 1
//            let token = (password as NSString).substring(with: result.range)
//            let match = Match(i: i, j: j, token: token)
//            match.pattern = patternName
//
//            if patternName == "date" && result.numberOfRanges == 6 {
//                var month: Int
//                var day: Int
//                var year: Int
//                do {
//                    month = Int((password as NSString).substring(with: result.range(at: 1))) ?? 0
//                    day = Int((password as NSString).substring(with: result.range(at: 3))) ?? 0
//                    year = Int((password as NSString).substring(with: result.range(at: 5))) ?? 0
//                }
//
//                match.separator = result.range(at: 2).location < password.count ? (password as NSString).substring(with: result.range(at: 2)) : ""
//
//                if month >= 12 && month <= 31 && day <= 12 { // tolerate both day-month and month-day order
//                    let temp = day
//                    day = month
//                    month = temp
//                }
//                if day > 31 || month > 12 {
//                    continue
//                }
//                if year < 25 {
//                    year += 2000
//                } else if year < 100 {
//                    year += 1900
//                }
//
//                match.day = day
//                match.month = month
//                match.year = year
//            }
//
//            matches.append(match)
//        }
//
//        return matches
//    }
//}
//
//
//struct MatchResources {
//    static let shared = MatchResources()
//    var dictionaryMatchers: [MatcherBlock] = []
//    var graphs: [String: [String: [String?]]] = [:]
//
//    private init() {
//        dictionaryMatchers = loadFrequencyLists()
//        graphs = Helpers.shared.loadAdjacencyGraphs()
//    }
//
//    private func loadFrequencyLists() -> [MatcherBlock] {
//        var matchers: [MatcherBlock] = []
//
//        guard let path = Bundle.module.url(forResource: "frequency-lists", withExtension: "json"),
//              let data = try? Data(contentsOf: path) else {
//            return []
//        }
//
//        do {
//            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: [String]] else {
//                return []
//            }
//
//            for (name, list) in json {
//                let rankedDict = buildRankedDict(list)
//                matchers.append(buildDictMatcher(name, rankedDict: rankedDict))
//            }
//
//            return matchers
//        } catch {
//            print("Error parsing frequency lists: \(error)")
//            return []
//        }
//    }
//
//    private func buildRankedDict(_ words: [String]) -> [String: Int] {
//        var dict: [String: Int] = [:]
//
//        for (index, word) in words.enumerated() {
//            dict[word] = index + 1
//        }
//
//        return dict
//    }
//
//    fileprivate func buildDictMatcher(_ name: String, rankedDict: [String: Int]) -> MatcherBlock {
//        return { (password: String) in
//            let matches: [Match] = self.dictionaryMatch(password: password, rankedDict: rankedDict)
//
//            for index in matches.indices {
//                matches[index].dictionaryName = name
//            }
//
//            return matches
//        }
//    }
//
//    private func dictionaryMatch(password: String, rankedDict: [String: Int]) -> [Match] {
//        var result: [Match] = []
//        let length = password.count
//        let passwordLower = password.lowercased()
//
//        for i in 0..<length {
//            for j in i..<length {
//                let start = passwordLower.index(passwordLower.startIndex, offsetBy: i)
//                let end = passwordLower.index(passwordLower.startIndex, offsetBy: j)
//                let range = start...end
//                let word = String(passwordLower[range])
//                if let rank = rankedDict[word] {
//                    let match = Match(i: i, j: j, token: String(password[range]))
//                    match.pattern = "dictionary"
//                    match.matchedWord = word
//                    match.rank = rank
//                    result.append(match)
//                }
//            }
//        }
//
//        return result
//    }
//}
