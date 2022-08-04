//
//  BoardBackground.swift
//  islobsterble
//  View for styling the game board in aggregate.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct BoardBackground: View {
    let boardSquares: [[BoardSquare]]
    @EnvironmentObject var boardSlots: SlotGrid
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<self.boardSquares.count, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<self.boardSquares[0].count, id: \.self) { column in
                        self.boardSquares[row][column]
                    }
                }
            }
        }.border(Color.black, width: 2)
    }
}
