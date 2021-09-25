//
//  ContentView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-03.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI



struct ContentView: View {
    @ObservedObject var accessToken: ManagedAccessToken = ManagedAccessToken()
    
    var body: some View {
        LoginView().environmentObject(accessToken).environment(\.sizeCategory, .large)
    }
}

//var previewBoardSlots = SlotGrid(num_rows: 15, num_columns: 15)
//var previewRackSlots = SlotRow(num_slots: 7)

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView().environmentObject(previewBoardSlots).environmentObject(previewRackSlots)
//    }
//}
