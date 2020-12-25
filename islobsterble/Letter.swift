//
//  TileObjects.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct Letter: Equatable {
    let letter: Character
    let is_blank: Bool
    let value: Int?
    
    init(letter: Character, is_blank: Bool) {
        self.letter = letter
        self.is_blank = is_blank
        self.value = nil
    }
    init(letter: Character, is_blank: Bool, value: Int?) {
        self.letter = letter
        self.is_blank = is_blank
        self.value = value
    }
    
    static func ==(lhs: Letter, rhs: Letter) -> Bool {
        return lhs.letter == rhs.letter && lhs.is_blank == rhs.is_blank && lhs.value == rhs.value
    }
}



