//
//  Matcher.swift
//
//
//  Created by Christopher DeVito on 2/11/24.
//

typealias MatcherBlock = (String) -> [Match]

class Match {
    var pattern: String = ""
    var i: Int = 0
    var j: Int = 0
    var token: String = ""
    var entropy: Float = 0.0
    var cardinality: Int = 0
    var guesses: Int? = nil
    var guessesLog10: Double? = nil

    // Dictionary Match
    var matchedWord: String? = nil
    var dictionaryName: String? = nil
    var rank: Int? = nil
    var baseEntropy: Float? = nil
    var upperCaseEntropy: Float? = nil

    // L33t Match
    var l33t: Bool? = nil
    var sub: [String: String]? = nil
    var subDisplay: String? = nil
    var l33tEntropy: Float? = nil

    // Spatial Match
    var graph: String? = nil
    var turns: Int? = nil
    var shiftedCount: Int? = nil

    // Repeat Match
    var repeatedChar: String? = nil
    var repeatCount: Int? = nil
    var baseToken: String? = nil

    // Sequence Match
    var sequenceName: String? = nil
    var sequenceSpace: Int? = nil
    var ascending: Bool? = nil

    // Date Match
    var year: Int? = nil
    var month: Int? = nil
    var day: Int? = nil
    var separator: String? = nil

    // Dictionary Guesses
    var baseGuesses: Int? = nil
    var uppercaseVariations: Int? = nil
    var l33tVariations: Int? = nil
    var reversed: Bool? = nil

    // Regex Match
    var regexName: String? = nil
    var regexMatch: [String]? = nil

    public init(i: Int, j: Int, token: String) {
        self.i = i
        self.j = j
        self.token = token
    }
}

extension Match: Equatable {
    static func == (lhs: Match, rhs: Match) -> Bool {
        return lhs.pattern == rhs.pattern &&
            lhs.i == rhs.i &&
            lhs.j == rhs.j &&
            lhs.token == rhs.token &&
            lhs.entropy == rhs.entropy &&
            lhs.cardinality == rhs.cardinality &&
            lhs.guesses == rhs.guesses &&
            lhs.guessesLog10 == rhs.guessesLog10 &&
            lhs.matchedWord == rhs.matchedWord &&
            lhs.dictionaryName == rhs.dictionaryName &&
            lhs.rank == rhs.rank &&
            lhs.baseEntropy == rhs.baseEntropy &&
            lhs.upperCaseEntropy == rhs.upperCaseEntropy &&
            lhs.l33t == rhs.l33t &&
            lhs.sub == rhs.sub &&
            lhs.subDisplay == rhs.subDisplay &&
            lhs.l33tEntropy == rhs.l33tEntropy &&
            lhs.graph == rhs.graph &&
            lhs.turns == rhs.turns &&
            lhs.shiftedCount == rhs.shiftedCount &&
            lhs.repeatedChar == rhs.repeatedChar &&
            lhs.repeatCount == rhs.repeatCount &&
            lhs.sequenceName == rhs.sequenceName &&
            lhs.sequenceSpace == rhs.sequenceSpace &&
            lhs.ascending == rhs.ascending &&
            lhs.year == rhs.year &&
            lhs.month == rhs.month &&
            lhs.day == rhs.day &&
            lhs.separator == rhs.separator &&
            lhs.baseGuesses == rhs.baseGuesses &&
            lhs.uppercaseVariations == rhs.uppercaseVariations &&
            lhs.l33tVariations == rhs.l33tVariations &&
            lhs.reversed == rhs.reversed &&
            lhs.regexName == rhs.regexName &&
            lhs.regexMatch == rhs.regexMatch
    }
}
