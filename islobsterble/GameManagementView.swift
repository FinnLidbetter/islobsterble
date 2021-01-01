//
//  GameManagementView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct GameManagementView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var activeGames: ActiveGames = ActiveGames(games: [])
    
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
            ForEach(0..<activeGames.games.count, id: \.self) { index in
                NavigationLink(destination: PlaySpace(gameId: String(self.activeGames.games[index].id))) {
                    Text(self.activeGames.games[index].display())
                }
            }
            Text("Completed Games")
        }
        .navigationBarTitle("Menu", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: logoutButton)
        .onAppear {
            self.fetchActiveGames()
        }
    }
    
    func fetchActiveGames() {
        guard let url = URL(string: ROOT_URL + "api/games") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let decodedGames = try? decoder.decode(ActiveGames.self, from: data) {
                        self.activeGames = decodedGames
                    }
                }
            }
        }.resume()
    }
    
    var logoutButton: some View {
        Button(action: { self.logout() }) {
            HStack {
                Image("back_arrow").aspectRatio(contentMode: .fit)
                Text("Logout")
            }
        }
    }
    private func logout() {
        guard let url = URL(string: ROOT_URL + "auth/logout") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    print(response)
                }
            } else {
                print(error!)
            }
        }.resume()
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

struct ActiveGames: Codable {
    let games: [GameInfo]
}

struct GameInfo: Codable {
    let id: Int
    let game_players: [GamePlayer]
    let whose_turn_name: String
    let started: Date
    let completed: Date?
    
    func display() -> String {
        var displayEntries: [String] = []
        for gamePlayer in self.game_players {
            displayEntries.append("\(gamePlayer.player.display_name): \(gamePlayer.score)")
        }
        displayEntries.append("\(self.whose_turn_name) to play")
        return displayEntries.joined(separator: "\n")
    }
}
struct GamePlayer: Codable {
    let score: Int
    let player: Player
}
struct Player: Codable {
    let display_name: String
}
