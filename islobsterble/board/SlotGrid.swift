//
//  SlotGrid.swift
//  islobsterble
//  Object for tracking the locations of the board squares.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

class SlotGrid: ObservableObject {
    @Published var grid: [[CGRect]]
    
    init(num_rows: Int, num_columns: Int) {
        self.grid = [[CGRect]](repeating: [CGRect](repeating: .zero, count: num_columns), count: num_rows)
    }
    
    func update(row: Int, column: Int, rect: CGRect) {
        if self.grid[row][column] != rect {
            DispatchQueue.main.async {
                self.grid[row][column] = rect
            }
        }
    }
}
