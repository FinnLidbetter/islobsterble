//
//  StatsView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct StatsView: View {
    @State private var wins = 0
    @State private var draws = 0
    @State private var losses = 0
    
    var body: some View {
        VStack {
            HStack {
                Text("Wins: \(self.wins)")
                Spacer()
                Text("Draws: \(self.draws)")
                Spacer()
                Text("Losses: \(self.losses)")
            }
        }.navigationBarTitle("Stats", displayMode: .inline)
    }
}
