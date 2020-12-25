//
//  RackForeground.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct RackForeground: View {
    var tiles: [Tile]
    var shuffleState: [Tile]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<self.tiles.count) { tileIndex in
                ZStack {
                    self.shuffleState[tileIndex]
                    self.tiles[tileIndex]
                }
            }
        }
    }
}
