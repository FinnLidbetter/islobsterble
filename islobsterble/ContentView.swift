//
//  ContentView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-03.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI



struct ContentView: View {
    @EnvironmentObject var boardSlots: SlotGrid
    @EnvironmentObject var rackSlots: SlotRow
    
    var body: some View {
        LoginView()
//        VStack {
//            PlaySpace(gameId: "1")
//        }
    }
}

var previewBoardSlots = SlotGrid(num_rows: NUM_BOARD_ROWS, num_columns: NUM_BOARD_COLUMNS)
var previewRackSlots = SlotRow(num_slots: NUM_RACK_TILES)

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(previewBoardSlots).environmentObject(previewRackSlots)
    }
}

