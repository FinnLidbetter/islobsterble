//
//  RackForeground.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct RackForeground: View {
    let tiles: [Tile]
    let shuffleState: [Tile]
    let showingBlankPicker: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<self.tiles.count) { tileIndex in
                ZStack {
                    self.shuffleState[tileIndex].allowsHitTesting(false)
                    self.tiles[tileIndex].allowsHitTesting((self.tiles[tileIndex].face != INVISIBLE_LETTER && !self.showingBlankPicker))
                }
            }
        }
    }
}
