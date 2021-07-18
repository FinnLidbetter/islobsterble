//
//  ActionPanel.swift
//  islobsterble
//  View for managing actions that can be taken while in a game.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ActionPanel: View {
    @Binding var loggedIn: Bool
    let gameId: String
    let rackTilesOnBoard: Bool
    let showingPicker: Bool
    
    var onShuffle: () -> Void
    var onRecall: () -> Void
    var onPass: () -> Void
    var onPlay: () -> Void
    var onExchange: () -> Void
    
    
    var body: some View {
        HStack {
            // Move history
            NavigationLink(destination: MoveHistoryView(gameId: self.gameId, loggedIn: self.$loggedIn)) {
                //Image("MoveHistoryIcon").renderingMode(.original)
                Text("H")
            }.isDetailLink(false)
            // Dictionary
            NavigationLink(destination: DictionaryView(gameId: self.gameId, loggedIn: self.$loggedIn)) {
                //Image("DictionaryIcon").renderingMode(.original)
                Text("D")
            }.isDetailLink(false)
            // Exchange
            Button(action: self.onExchange) {
                //Image("ExchangeIcon")
                Text("E")
            }
            // Shuffle/recall
            Button(action: self.rackTilesOnBoard ? self.onRecall : self.onShuffle) {
                //Image(self.rackTilesOneBoard ? "RecallIcon" : "ShuffleIcon").renderingMode(.original)
                Text(self.rackTilesOnBoard ? "R" : "S")
            }
            // Pass/play
            Button(action: self.rackTilesOnBoard ? self.onPlay : self.onPass) {
                //Image(self.rackTilesOnBoard ? "PlayIcon" : "PassIcon").renderingMode(.original)
                Text("P")
            }
        }.allowsHitTesting(!self.showingPicker)
    }
    
}
