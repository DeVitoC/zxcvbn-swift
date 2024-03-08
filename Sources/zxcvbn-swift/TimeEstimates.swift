//
//  Matcher.swift
//
//
//  Created by Christopher DeVito on 3/8/24.
//

import Foundation

class TimeEstimates {
    func estimateAttackTimes(guesses: Double) -> TimeEstimateReturn {
        let crackTimesSeconds: [String: Double] = [
            "onlineThrottling100PerHour": guesses / (100.0 / 3600.0),
            "onlineNoThrottling10PerSecond": guesses / 10.0,
            "offlineSlowHashing1e4PerSecond": guesses / 1e4,
            "offlineFastHashing1e10PerSecond": guesses / 1e10
        ]

        var crackTimesDisplay: [String: String] = [:]
        for (scenario, seconds) in crackTimesSeconds {
            crackTimesDisplay[scenario] = displayTime(seconds: seconds)
        }

        let score = guessesToScore(guesses: guesses)

        return TimeEstimateReturn(crackTimesSeconds: crackTimesSeconds, crackTimesDisplay: crackTimesDisplay, score: score)
    }

    private func displayTime(seconds: Double) -> String {
        let minute = 60.0
        let hour = minute * 60.0
        let day = hour * 24.0
        let month = day * 31.0
        let year = month * 12.0
        let century = year * 100.0
        var displayNum: Double = 0.0
        var displayStr: String
        switch seconds {
        case 0..<1:
                displayStr = "less than a second"
        case 1..<minute:
            displayNum = round(seconds)
                displayStr = "\(displayNum) second"
        case minute..<hour:
            displayNum = round(seconds / minute)
                displayStr = "\(displayNum) minute"
        case hour..<day:
            displayNum = round(seconds / hour)
                displayStr = "\(displayNum) hour"
        case day..<month:
            displayNum = round(seconds / day)
                displayStr = "\(displayNum) day"
        case month..<year:
            displayNum = round(seconds / month)
                displayStr = "\(displayNum) month"
        case year..<century:
            displayNum = round(seconds / year)
            displayStr = "\(displayNum) year"
        default:
            displayStr = "centuries"
        }

        if displayNum > 1 {
            displayStr += "s"
        }

        return displayStr
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
    let crackTimesSeconds: [String: Double]
    let crackTimesDisplay: [String: String]
    let score: Int
}
