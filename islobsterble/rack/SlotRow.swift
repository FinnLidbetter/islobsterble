//
//  SlotRow.swift
//  islobsterble
//  View for tracking the locations of the rack slots.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

class SlotRow: ObservableObject {
    @Published var slots: [CGRect]
    
    init(num_slots: Int) {
        self.slots = [CGRect](repeating: .zero, count: num_slots)
    }
    
    func update(index: Int, rect: CGRect) {
        if self.slots[index] != rect {
            DispatchQueue.main.async {
                self.slots[index] = rect
            }
        }
    }
}
