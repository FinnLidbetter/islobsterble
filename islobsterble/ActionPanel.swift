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
                Text("History")
            }.isDetailLink(false)
            // Dictionary
            NavigationLink(destination: DictionaryView(gameId: self.gameId, loggedIn: self.$loggedIn)) {
                //Image("DictionaryIcon").renderingMode(.original)
                Text("Dictionary")
            }.isDetailLink(false)
            // Exchange
            Button(action: self.onExchange) {
                //Image("ExchangeIcon")
                Text("Exchange")
            }
            // Shuffle/recall
            Button(action: self.rackTilesOnBoard ? self.onRecall : self.onShuffle) {
                //Image(self.rackTilesOneBoard ? "RecallIcon" : "ShuffleIcon").renderingMode(.original)
                Text(self.rackTilesOnBoard ? "Recall" : "Shuffle")
            }
            // Pass/play
            Button(action: self.rackTilesOnBoard ? self.onPlay : self.onPass) {
                //Image(self.rackTilesOnBoard ? "PlayIcon" : "PassIcon").renderingMode(.original)
                Text(self.rackTilesOnBoard ? "Play" : "Pass")
            }
        }.allowsHitTesting(!self.showingPicker)
    }
    
}
