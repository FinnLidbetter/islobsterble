//
//  ScorePanel.swift
//  islobsterble
//  View for displaying the player scores.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ScorePanel: View {
    let playerScores: [PlayerScore]
    let turnNumber: Int
    
    var body: some View {
        HStack {
            Text(self.playerScores.count > 0 ? "\(self.playerScores[0].playerName): \(self.playerScores[0].score)" : "").padding().background(Rectangle().fill(self.playerScores.count > 0 && self.turnNumber % self.playerScores.count == self.playerScores[0].turnOrder ? Color(.blue) : Color(.clear)))
            ForEach(min(self.playerScores.count, 1)..<self.playerScores.count, id: \.self) { index in
                Spacer()
                Text("\(self.playerScores[index].playerName): \(self.playerScores[index].score)").padding().background(Rectangle().fill(self.turnNumber % self.playerScores.count == self.playerScores[index].turnOrder ? Color(.blue) : Color(.clear)))
            }
        }.padding().background(Rectangle().fill(Color(.yellow)))
    }
}

struct PlayerScore {
    let playerId: Int
    let playerName: String
    let score: Int
    let turnOrder: Int
}
