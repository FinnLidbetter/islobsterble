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
}
