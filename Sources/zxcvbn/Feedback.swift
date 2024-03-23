//
//  Feedback.swift
//
//
//  Created by Christopher DeVito on 3/10/24.
//

import Foundation

class Feedback {
    func getFeedback(score: Int, sequence: [Match]) -> [String: [String]] {
        if sequence.isEmpty {
            return ["warning": [],
                    "suggestions": [NSLocalizedString("Use a few words, avoid common phrases.", comment: ""),
                                    NSLocalizedString("No need for symbols, digits, or uppercase letters.", comment: "")]]
        }

        if score > 2 {
            return ["warning": [], "suggestions": []]
        }

        var longestMatch = sequence[0]
        for match in sequence.dropFirst() {
            if match.token.count > longestMatch.token.count {
                longestMatch = match
            }
        }

        var feedback = getMatchFeedback(match: longestMatch, isSoleMatch: sequence.count == 1)
        let extraFeedback = NSLocalizedString("Add another word or two. Uncommon words are better.", comment: "")

        if !feedback.isEmpty {
            feedback["suggestions"]?.insert(extraFeedback, at: 0)
            if feedback["warning"]?.isEmpty ?? true {
                feedback["warning"] = []
            }
        } else {
            feedback = ["warning": [], "suggestions": [extraFeedback]]
        }

        return feedback
    }

    func getMatchFeedback(match: Match, isSoleMatch: Bool) -> [String: [String]] {
        switch match.pattern {
            case "dictionary":
                return getDictionaryMatchFeedback(match: match, isSoleMatch: isSoleMatch)
            case "spatial":
                let warning: String
                if match.turns == 1 {
                    warning = NSLocalizedString("Straight rows of keys are easy to guess.", comment: "")
                } else {
                    warning = NSLocalizedString("Short keyboard patterns are easy to guess.", comment: "")
                }
                return ["warning": [warning], "suggestions": [NSLocalizedString("Use a longer keyboard pattern with more turns.", comment: "")]]
            case "repeat":
                let warning: String
                if let baseToken = match.baseToken, baseToken.count == 1 {
                    warning = NSLocalizedString("Repeats like \"aaa\" are easy to guess.", comment: "")
                } else {
                    warning = NSLocalizedString("Repeats like \"abcabcabc\" are only slightly harder to guess than \"abc\".", comment: "")
                }
                return ["warning": [warning], "suggestions": [NSLocalizedString("Avoid repeated words and characters.", comment: "")]]
            case "sequence":
                return ["warning": [NSLocalizedString("Sequences like \"abc\" or \"6543\" are easy to guess.", comment: "")],
                        "suggestions": [NSLocalizedString("Avoid sequences.", comment: "")]]
            case "regex":
                if let regexName = match.regexName, regexName == "recent_year" {
                    return ["warning": [NSLocalizedString("Recent years are easy to guess.", comment: "")],
                            "suggestions": [NSLocalizedString("Avoid recent years.", comment: ""),
                                            NSLocalizedString("Avoid years that are associated with you.", comment: "")]]
                } else if match.pattern == "date" {
                    return ["warning": [NSLocalizedString("Dates are often easy to guess.", comment: "")],
                            "suggestions": [NSLocalizedString("Avoid dates and years that are associated with you.", comment: "")]]
                }
            default:
                break
        }
        return [:]
    }

    func getDictionaryMatchFeedback(match: Match, isSoleMatch: Bool) -> [String: [String]] {
        var warning = ""
        var suggestions: [String] = []

        let dictionaryName = match.dictionaryName
        switch dictionaryName {
            case "passwords":
                if isSoleMatch && !(match.l33t == true) && !(match.reversed == true), let rank = match.rank {
                    if rank <= 10.0 {
                        warning = NSLocalizedString("This is a top-10 common password.", comment: "")
                    } else if rank <= 100.0 {
                        warning = NSLocalizedString("This is a top-100 common password.", comment: "")
                    } else {
                        warning = NSLocalizedString("This is a very common password.", comment: "")
                    }
                } else if let guessesLog10 = match.guessesLog10, guessesLog10 <= 4 {
                    warning = NSLocalizedString("This is similar to a commonly used password.", comment: "")
                }
            case "english_wikipedia":
                if isSoleMatch {
                    warning = NSLocalizedString("A word by itself is easy to guess.", comment: "")
                }
            case "surnames", "male_names", "female_names":
                if isSoleMatch {
                    warning = NSLocalizedString("Names and surnames by themselves are easy to guess.", comment: "")
                } else {
                    warning = NSLocalizedString("Common names and surnames are easy to guess.", comment: "")
                }
            default:
                break
        }

        let word = match.token
        let startUpperRegex = try? NSRegularExpression(pattern: "^[A-Z][^A-Z]+$", options: [])
        let allUpperRegex = try? NSRegularExpression(pattern: "^[^a-z]+$", options: [])

        if let startUpperMatch = startUpperRegex?.firstMatch(in: word, options: [], range: NSRange(location: 0, length: word.count)), startUpperMatch.range.length > 0 {
            suggestions.append(NSLocalizedString("Capitalization doesn't help very much.", comment: ""))
        } else if let allUpperMatch = allUpperRegex?.firstMatch(in: word, options: [], range: NSRange(location: 0, length: word.count)), allUpperMatch.range.length > 0, word.lowercased() != word {
            suggestions.append(NSLocalizedString("All-uppercase is almost as easy to guess as all-lowercase.", comment: ""))
        }

        if (match.reversed == true) && word.count >= 4 {
            suggestions.append(NSLocalizedString("Reversed words aren't much harder to guess.", comment: ""))
        }

        if match.l33t == true {
            suggestions.append(NSLocalizedString("Predictable substitutions like '@' instead of 'a' don't help very much.", comment: ""))
        }

        return ["warning": [warning], "suggestions": suggestions]
    }
}
