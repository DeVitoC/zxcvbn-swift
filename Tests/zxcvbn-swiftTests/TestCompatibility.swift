//
//  TestCompatibility.swift
//  
//
//  Created by Christopher DeVito on 3/10/24.
//

import XCTest
@testable import zxcvbn_swift

class TestCompatibility: XCTestCase {
    func checkSection(_ test: [String : Any]) -> (Int, Int) {
        var scoresCollision = 0
        var guessesCollision = 0
        
            guard let password = test["password"] as? String,
                  let score = test["score"] as? Int else {
                XCTFail("Missing values in test case: password - \(String(describing: test["password"])), guesses - \(String(describing: test["guesses"])), score - \(String(describing: test["score"])).")
                return (scoresCollision, guessesCollision)
            }

            let zxcvbnResult = zxcvbn(password)

            if let guesses = test["guesses"] as? Int {
                if abs(zxcvbnResult.guesses - Double(guesses)) > 1 && zxcvbnResult.guesses < 1000000000000 {
                    guessesCollision += 1
                    printFailure(test, zxcvbnResult)
                }
                XCTAssertEqual(zxcvbnResult.guesses, Double(guesses), "password: \(password), sequence: \(zxcvbnResult.sequence.map{ $0.sequenceName ?? "no sequence name" }.joined(separator: ", "))")
            } else if let guesses = test["guesses"] as? Double {
                if abs(zxcvbnResult.guesses - guesses) > 1 && zxcvbnResult.guesses < 1000000000000 {
                    guessesCollision += 1
                    printFailure(test, zxcvbnResult)
                }
                XCTAssertEqual(zxcvbnResult.guesses, guesses, "password: \(password), sequence: \(zxcvbnResult.sequence)")
            } else {
                XCTFail("Missing guesses value in test case: guesses - \(String(describing: test["guesses"])).")
                return (scoresCollision, guessesCollision)
            }

            if zxcvbnResult.score != (score) {
                scoresCollision += 1
                printFailure(test, zxcvbnResult)
            }
            XCTAssertEqual(zxcvbnResult.score, score, password)

        return (scoresCollision, guessesCollision)
    }

    func testCompatibility() throws {
        let tests = TestValues().testValues
        let testsCount = tests.count

        var scoresCollision = 0
        var guessesCollision = 0

        for testIndex in 0..<testsCount {
            let test = tests[testIndex]

            let result = autoreleasepool { () -> (Int, Int) in 
                let testResult = checkSection(test)
                scoresCollision += testResult.0
                guessesCollision += testResult.1

                return testResult
            }
        }

        let tests2 = TestValues().testValues
        let testsCount2 = tests.count

        for testIndex in 0..<testsCount2 {
            let test = tests[testIndex]

            let result = autoreleasepool { () -> (Int, Int) in
                let testResult = checkSection(test)
                scoresCollision += testResult.0
                guessesCollision += testResult.1

                return testResult
            }
        }

        if guessesCollision == 0 && scoresCollision == 0 {
            print("Passed!")
        } else {
            XCTFail("Failed! guesses_collision: \(guessesCollision) scores_collision: \(scoresCollision)")
        }
    }

    private func printFailure(_ test: [String: Any], _ result: MostGuessableMatchSequenceResult) {
        print("========================================= expected: \(test) results: \(result)")
    }
}
