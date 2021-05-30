//
//  RackSquare.swift
//  islobsterble
//  View for styling a slot in the rack.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct RackSquare: View {
    let size: Int
    let color: Color
    let index: Int
    @EnvironmentObject var rackSlots: SlotRow
 
    var body: some View {
        Rectangle()
            .fill(self.color)
            .frame(width: CGFloat(self.size), height: CGFloat(self.size))
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            self.rackSlots.slots[self.index] = geo.frame(in: .global)
                    }
                }
            )
    }
}
