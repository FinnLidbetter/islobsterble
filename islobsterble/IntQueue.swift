//
//  IntQueue.swift
//  islobsterble
//  Data structure class.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import Foundation

class IntQueue {
    // This implementation is not safe against exceeding
    // the initially specified size.
    let maxSize: Int
    private var front: Int
    private var back: Int
    private var q: [Int?]
    
    init(maxSize: Int) {
        self.maxSize = maxSize
        self.q = [Int?](repeating: nil, count: maxSize)
        self.front = 0
        self.back = maxSize - 1
    }
    
    func getSize() -> Int {
        if back < front {
            let diff = back + maxSize - front + 1
            if diff == maxSize {
                return self.q[front] == nil ? 0 : maxSize
            }
            return diff
        }
        let diff = back - front + 1
        if diff == maxSize {
            return self.q[front] == nil ? 0 : maxSize
        }
        return diff
    }
    func offer(_ val: Int) {
        self.back += 1
        if self.back >= maxSize {
            self.back -= maxSize
        }
        assert(self.q[self.back] == nil, "The queue is too small!")
        self.q[self.back] = val
    }
    func poll() -> Int? {
        let val = self.q[self.front]
        self.q[self.front] = nil
        self.front += 1
        if self.front >= maxSize {
            self.front -= maxSize
        }
        return val
    }
}
