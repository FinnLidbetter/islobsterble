//
//  TileObjects.swift
//  islobsterble
//  Struct for storing the contents of a tile.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct Letter: Equatable, Hashable {
    let letter: Character
    let is_blank: Bool
    let value: Int?
    
    enum CodingKeys: String, CodingKey {
        case letter
        case is_blank
        case value
    }
    
    static func ==(lhs: Letter, rhs: Letter) -> Bool {
        return lhs.letter == rhs.letter && lhs.is_blank == rhs.is_blank && lhs.value == rhs.value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(letter)
        hasher.combine(is_blank)
        hasher.combine(value)
    }
}

extension Letter: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        letter = try Character(values.decode(String.self, forKey: .letter))
        is_blank = try values.decode(Bool.self, forKey: .is_blank)
        value = try values.decode(Int?.self, forKey: .value)
    }
}
extension Letter: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(String(letter), forKey: .letter)
        try container.encode(is_blank, forKey: .is_blank)
        try container.encode(value, forKey: .value)
    }
}

