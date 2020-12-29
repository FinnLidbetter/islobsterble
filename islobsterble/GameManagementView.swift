//
//  GameManagementView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct GameManagementView: View {
    @State private var activeGames: [GameInfo] = [GameInfo(gameId: "1", scores: ["Player 1": 10, "Player 2": 7], whoseTurn: "Player 2")]
    
    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: SettingsView()) {
                    // Image("SettingsIcon").renderingMode(.original)
                    Text("Settings")
                }
                NavigationLink(destination: StatsView()) {
                    // Image("StatsIcon").renderingMode(.original)
                    Text("Stats")
                }
                NavigationLink(destination: FriendsView()) {
                    // Image("ContactsIcon").renderingMode(.original)
                    Text("Contacts")
                }
                NavigationLink(destination: NewGameView()) {
                    // Image("NewGameIcon").renderingMode(.original)
                    Text("New Game")
                }
            }
            Text("Active Games")
            ForEach(0..<activeGames.count) { index in
                NavigationLink(destination: PlaySpace(gameId: self.activeGames[index].gameId)) {
                    Text(self.activeGames[index].display())
                }
            }
            Text("Completed Games")
        }
        .navigationBarTitle("Menu", displayMode: .inline)
        .onAppear {
            self.fetchActiveGames()
        }
    }
    func fetchActiveGames() {
        guard let url = URL(string: ROOT_URL + "active-games") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    
                }
            }
        }.resume()
    }
}

struct GameInfo {
    let gameId: String
    let scores: [String: Int]
    let whoseTurn: String
    
    func display() -> String {
        var displayEntries: [String] = []
        for (player, score) in self.scores {
            displayEntries.append("\(player): \(score)")
        }
        displayEntries.append("\(self.whoseTurn) to play")
        return displayEntries.joined(separator: "\n")
    }
}
