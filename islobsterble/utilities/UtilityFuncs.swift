//
//  UtilityFuncs.swift
//  islobsterble
//  Utility functions for general usage.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import Foundation

class UtilityFuncs {
    static func permutation(size: Int) -> [Int] {
        var order: [Int] = []
        for index in 0..<size {
            order.append(index)
        }
        for index in 0..<size {
            let swapIndex = Int.random(in: 0..<(size - index))
            let tmp = order[swapIndex]
            order[swapIndex] = order[size - index - 1]
            order[size - index - 1] = tmp
        }
        return order
    }
}
