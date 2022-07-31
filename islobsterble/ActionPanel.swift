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
    @Binding var inGame: Bool
    let gameId: String
    let tilesRemaining: Int
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
            NavigationLink(destination: MoveHistoryView(gameId: self.gameId, loggedIn: self.$loggedIn, inGame: self.$inGame)) {
                VStack {
                    Image(systemName: "list.number").font(.system(size: 35.0))
                    Text("Scores").font(.system(size: 12.0))
                }.frame(width: 60, height: 50)
            }.isDetailLink(false)
            Spacer()
            // Dictionary
            NavigationLink(destination: DictionaryView(gameId: self.gameId, loggedIn: self.$loggedIn, inGame: self.$inGame)) {
                VStack {
                    Image(systemName: "character.book.closed").font(.system(size: 35.0))
                    Text("Dictionary").font(.system(size: 11.0))
                }.frame(width: 60, height: 50)
            }.isDetailLink(false)
            Spacer()
            // Exchange
            Button(action: self.onExchange) {
                ZStack {
                    VStack {
                        Image(systemName: "bag").font(.system(size: 35.0))
                        Text("Exchange").font(.system(size: 12.0))
                    }
                    Text("\(self.tilesRemaining)").font(.system(size: 12.0)).padding(.bottom, 5)
                }.frame(width: 60, height: 50)
            }
            Spacer()
            // Shuffle/recall
            Button(action: self.rackTilesOnBoard ? self.onRecall : self.onShuffle) {
                VStack {
                    if self.rackTilesOnBoard {
                        Image(systemName: "arrow.down").font(.system(size: 30.0))
                    } else {
                        Image(systemName: "arrow.left.arrow.right").font(.system(size: 30.0))
                    }
                    Text(self.rackTilesOnBoard ? "Recall" : "Shuffle").font(.system(size: 12.0))
                }.frame(width: 60, height: 50)
            }
            Spacer()
            // Pass/play
            Button(action: self.rackTilesOnBoard ? self.onPlay : self.onPass) {
                VStack {
                    if self.rackTilesOnBoard {
                        Image(systemName: "arrowtriangle.forward").font(.system(size: 35.0))
                    } else {
                        Image(systemName: "arrow.right.to.line").font(.system(size: 35.0))
                    }
                    //Image(systemName: self.rackTilesOnBoard ? "arrowtriangle.forward" : "arrow.right.to.line").font(.system(size: 35.0))
                    Text(self.rackTilesOnBoard ? "Play" : "Pass").font(.system(size: 12.0))
                }.frame(width: 60, height: 50)
            }
        }.allowsHitTesting(!self.showingPicker)
    }
    
}
