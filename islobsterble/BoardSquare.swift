//
//  BoardSquare.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct BoardSquare: View {
    
    let size: Int
    let color: Color
    let row: Int
    let column: Int
    
    @EnvironmentObject var boardSlots: SlotGrid
    
    var body: some View {
        Rectangle()
            .fill(self.color)
            .border(Color.black)
            .frame(width: CGFloat(size), height: CGFloat(size))
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            self.boardSlots.grid[self.row][self.column] = geo.frame(in: .global)
                    }
                }
            )
    }
}
