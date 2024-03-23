//
//  MostGuessableMatchSequenceResult.swift
//
//
//  Created by Christopher DeVito on 3/10/24.
//

import Foundation

public struct MostGuessableMatchSequenceResult {
    public var password: String
    public var guesses: Double
    public var guessesLog10: Double
    var sequence: [Match]
    public var feedback: [String: [String]]?
    public var calcTime: TimeInterval?
    public var crackTimesSeconds: CrackTimesSeconds?
    public var crackTimesDisplay: CrackTimesDisplay?
    public var score: Int?
}

public struct CrackTimesSeconds {
    public var onlineThrottling100PerHour: Double
    public var onlineNoThrottling10PerSecond: Double
    public var offlineSlowHashing1e4PerSecond: Double
    public var offlineFastHashing1e10PerSecond: Double
}

public struct CrackTimesDisplay {
    public var onlineThrottling100PerHour: String!
    public var onlineNoThrottling10PerSecond: String!
    public var offlineSlowHashing1e4PerSecond: String!
    public var offlineFastHashing1e10PerSecond: String!

    init(onlineThrottling100PerHour: String,
         onlineNoThrottling10PerSecond: String,
         offlineSlowHashing1e4PerSecond: String,
         offlineFastHashing1e10PerSecond: String
    ) {
        self.onlineThrottling100PerHour = onlineThrottling100PerHour
        self.onlineNoThrottling10PerSecond = onlineNoThrottling10PerSecond
        self.offlineSlowHashing1e4PerSecond = offlineSlowHashing1e4PerSecond
        self.offlineFastHashing1e10PerSecond = offlineFastHashing1e10PerSecond
    }

    init(crackTimeSeconds: CrackTimesSeconds) {
        self.onlineThrottling100PerHour = displayTime(seconds: crackTimeSeconds.onlineThrottling100PerHour)
        self.onlineNoThrottling10PerSecond = displayTime(seconds: crackTimeSeconds.onlineNoThrottling10PerSecond)
        self.offlineSlowHashing1e4PerSecond = displayTime(seconds: crackTimeSeconds.offlineSlowHashing1e4PerSecond)
        self.offlineFastHashing1e10PerSecond = displayTime(seconds: crackTimeSeconds.offlineFastHashing1e10PerSecond)
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
}
