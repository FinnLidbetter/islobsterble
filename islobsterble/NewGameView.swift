//
//  NewGameView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct NewGameView: View {
    @State private var friends: [String: String] = ["": ""]
    @State private var chosenOpponents: [String] = []
    
    var body: some View {
        List {
            Text("New Game")
        }.navigationBarTitle("New Game", displayMode: .inline)
    }
}
