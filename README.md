## zxcvbn

A realistic password strength estimator.

This is a Pure Swift implementation based on the package zxcvbn created by the team at Dropbox. The original library, written for JavaScript, can be found [here](https://github.com/dropbox/zxcvbn).

This is currently the only Pure Swift implementation, which is required for use with Vapor, but also works well with any iOS or macOS project written in Swift


## Features

Tested in Swift 5.9
* Accepts user data to be added to the dictionaries that are tested against (name, birthdate, etc)
* Gives a score to the password, from 0 (terrible) to 4 (great)
* Provides feedback on the password and ways to improve it
* Returns time estimates on how long it would take to guess the password in different situations


## Installation

#### Installing in Vapor:
To your dependencies add
```swift
dependencies: [
    // Other packages
    .package(url: "https://github.com/DeVitoC/zxcvbn-swift", from: "1.00.02")
]
```
and to your targets add
```swift
targets: [
    .executableTarget(
        dependencies: [
            // Other dependencies 
            .product(name: "zxcvbn", package: "zxcvbn-swift")
        ]
    )
]
```

#### Installing in iOS:
From the menu select File -> Add Package Dependencies

Search for ``github.com/DeVitoC/zxcvbn-swift``

Select zxcvbn-swift (make sure it is from github.com/DeVitoC). 

Select "Up To Next Major Version"

Click "Add Package"


## Usage
Pass a password as the first parameter, and a list of user-provided inputs as the ``userInputs`` parameter (optional).

Example in Vapor with all possible properties of the return object shown and just returning the score.
```swift
import zxcvbn

//Other code
func checkPassword(req: Request) async throws -> Int {
    let password = try req.content.decode(String.self)
    let result = zxcvbn(password)

    let score = result.score ?? 0
    let calcTime = result.calcTime
    let feedback = result.feedback
    let guesses = result.guesses
    let guessesLog10 = result.guessesLog10
    let passwordResult = result.password

    let crackTimesSeconds = result.crackTimesSeconds
    let crackTimesSecondsOfflineFastHash = crackTimesSeconds?.offlineFastHashing1e10PerSecond
    let crackTimesSecondsOfflineSlowHash = crackTimesSeconds?.offlineSlowHashing1e4PerSecond
    let crackTimesSecondsOnlineThrottling10PerSecond = crackTimesSeconds?.onlineNoThrottling10PerSecond
    let crackTimesSecondsOnlineThrottling100PerSecond = crackTimesSeconds?.onlineThrottling100PerHour

    let crackTimesDisplay = result.crackTimesDisplay
    let crackTimesDisplayOfflineFastHash = crackTimesDisplay?.offlineFastHashing1e10PerSecond
    let crackTimesDisplayOfflineSlowHash = crackTimesDisplay?.offlineSlowHashing1e4PerSecond
    let crackTimesDisplayOnlineThrottling10PerSecond = crackTimesDisplay?.onlineNoThrottling10PerSecond
    let crackTimesDisplayOnlineThrottling100PerSecond = crackTimesDisplay?.onlineThrottling100PerHour

    return score
}
```


## Contribute

* Report an Issue: [https://github.com/DeVitoC/zxcvbn-swift/issues](https://github.com/DeVitoC/zxcvbn-swift/issues)
* Submit a Pull Request: [https://github.com/DeVitoC/zxcvbn-swift/pulls](https://github.com/DeVitoC/zxcvbn-swift/pulls)


## License
The project is licensed under the MIT license.
