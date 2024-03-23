//
//  Matcher.swift
//
//
//  Created by Christopher DeVito on 3/8/24.
//

import Foundation

class TimeEstimates {
    func estimateAttackTimes(guesses: Double) -> TimeEstimateReturn {
        let crackTimesSeconds = CrackTimesSeconds(
            onlineThrottling100PerHour: guesses / (100.0 / 3600.0),
            onlineNoThrottling10PerSecond: guesses / 10.0,
            offlineSlowHashing1e4PerSecond: guesses / 1e4,
            offlineFastHashing1e10PerSecond: guesses / 1e10
        )

        let crackTimesDisplay = CrackTimesDisplay(crackTimeSeconds: crackTimesSeconds)

        let score = guessesToScore(guesses: guesses)

        return TimeEstimateReturn(crackTimesSeconds: crackTimesSeconds, crackTimesDisplay: crackTimesDisplay, score: score)
    }

    private func guessesToScore(guesses: Double) -> Int {
        let delta = 5.0

        if guesses < 1e3 + delta {
            return 0
        } else if guesses < 1e6 + delta {
            return 1
        } else if guesses < 1e8 + delta {
            return 2
        } else if guesses < 1e10 + delta {
            return 3
        } else {
            return 4
        }
    }
}

struct TimeEstimateReturn {
    let crackTimesSeconds: CrackTimesSeconds
    let crackTimesDisplay: CrackTimesDisplay
    let score: Int
}
