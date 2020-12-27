//
//  BoardForeground.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct BoardForeground: View {
    let tiles: [[Tile]]
    let locked: [[Bool]]
    let showingPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<NUM_BOARD_ROWS) { row in
                HStack(spacing: 0) {
                    ForEach(0..<NUM_BOARD_COLUMNS) { column in
                        self.tiles[row][column].allowsHitTesting((!self.locked[row][column] && self.tiles[row][column].face != INVISIBLE_LETTER && !self.showingPicker))
                    }
                }
            }
        }
    }
}
