//
//  ScorePanel.swift
//  islobsterble
//  View for displaying the player scores.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let SCORE_PANEL_COLOR = Color(red: 155 / 255, green: 250 / 255, blue: 255 / 255)
let CURRENT_PLAYER_COLOR = Color(red: 70 / 255, green: 130 / 255, blue: 210 / 255)

struct ScorePanel: View {
    let playerScores: [PlayerScore]
    let turnNumber: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(self.playerScores.count > 0 ? "\(self.playerScores[0].playerName): \(self.playerScores[0].score)" : "").padding(10).background(Rectangle().fill(self.playerScores.count > 0 && self.turnNumber % self.playerScores.count == self.playerScores[0].turnOrder ? CURRENT_PLAYER_COLOR : Color(.clear)))
                ForEach(min(self.playerScores.count, 1)..<self.playerScores.count, id: \.self) { index in
                    Spacer()
                    Text("\(self.playerScores[index].playerName): \(self.playerScores[index].score)").padding(10).background(Rectangle().fill(self.turnNumber % self.playerScores.count == self.playerScores[index].turnOrder ? CURRENT_PLAYER_COLOR : Color(.clear)))
                }
            }.padding(10).background(Rectangle().fill(SCORE_PANEL_COLOR))
            Rectangle().fill(Color.black).frame(minWidth: 0, idealWidth: .infinity, maxWidth: .infinity, minHeight: 1, idealHeight: 2, maxHeight: 2, alignment: .center)
        }
    }
}

struct PlayerScore {
    let playerId: Int
    let playerName: String
    let score: Int
    let turnOrder: Int
}
