//
//  RackBackground.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct RackBackground: View {
    var rackSquares: [RackSquare]
    @EnvironmentObject var rackSlots: SlotRow
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<NUM_RACK_TILES) { tileIndex in
                self.rackSquares[tileIndex]
            }
        }
    }
}
