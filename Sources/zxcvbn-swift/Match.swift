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
    var regexMatch: String? = nil
}