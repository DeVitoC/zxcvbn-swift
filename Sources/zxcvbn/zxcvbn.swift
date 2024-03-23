import Foundation

public func zxcvbn(_ password: String, userInputs: [Any]? = nil) -> MostGuessableMatchSequenceResult {
    var sanitizedInputs = [String]()
    let matching = Matching()
    let helpers = Helpers.shared
    let scoring = Scoring()
    let timeEstimates = TimeEstimates()
    let feedback = Feedback()

    if let userInputs {
        for arg in userInputs {
            sanitizedInputs.append(String(describing: arg).lowercased())
        }
    }

    let start = Date()
    var rankedDictionaries = matching.rankedDictionaries
    rankedDictionaries["user_inputs"] = helpers.buildRankedDict(sanitizedInputs)

    let matches = matching.omnimatch(password: password, rankedDictionaries: rankedDictionaries)
    var result = scoring.mostGuessableMatchSequence(password: password, matches: matches)

    let calcTime = Date().timeIntervalSince(start)
    let attackTimes = timeEstimates.estimateAttackTimes(guesses: result.guesses)

    result.crackTimesSeconds = attackTimes.crackTimesSeconds
    result.crackTimesDisplay = attackTimes.crackTimesDisplay
    result.score = attackTimes.score

    result.calcTime = calcTime
    let score = result.score ?? 0
    result.feedback = feedback.getFeedback(score: score, sequence: result.sequence)

    return result
}
