//
//  MoveHistoryView.swift
//  islobsterble
//  View for showing the history of turns played.
//
//  Created by Finn Lidbetter on 2021-01-12.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import SwiftUI


struct MoveHistoryView: View {
    let gameId: String
    
    @State private var moves: [MoveSerializer] = []
    
    var body: some View {
        HStack {
            ForEach(0..<self.friends.count, id: \.self) { index in
                
            }
            List{
                Section(header: )
            }
        }
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}


struct MovesSerializer: Codable {
    let moves: [MoveSerializer]
}
struct MoveSerializer: Codable {
    let game_player: MoveGamePlayerSerializer
    let primary_word: String
    let secondary_words: String
    let tiles_exchanged: Int
    let turn_number: Int
    let score: Int
}
struct MoveGamePlayerSerializer: Codable {
    let player: MovePlayerSerializer
}
struct MovePlayerSerializer: Codable {
    let id: String
    let display_name: String
}
