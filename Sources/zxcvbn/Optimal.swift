//
//  Matcher.swift
//
//
//  Created by Christopher DeVito on 2/11/24.
//

import Foundation

class Optimal {
    var m: [[Int:Match]]
    var pi: [[Int: Double]]
    var g: [[Int: Double]]

    init(n: Int) {
        m = Array(repeating: Dictionary(), count: n)
        pi = Array(repeating: Dictionary(), count: n)
        g = Array(repeating: Dictionary(), count: n)
    }
}