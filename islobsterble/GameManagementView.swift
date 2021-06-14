//
//  GameManagementView.swift
//  islobsterble
//  View for the main screen.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct GameManagementView: View {
    @EnvironmentObject var accessToken: ManagedAccessToken
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var activeGames = [GameInfo]()
    @State private var completedGames = [GameInfo]()
    
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
                    Text("Friends")
                }
                NavigationLink(destination: NewGameView()) {
                    // Image("NewGameIcon").renderingMode(.original)
                    Text("New Game")
                }
            }
            Text("Active Games")
            ForEach(0..<activeGames.count, id: \.self) { index in
                NavigationLink(destination: PlaySpace(gameId: String(self.activeGames[index].id))) {
                    Text(self.activeGames[index].display())
                }
            }
            Text("Completed Games")
            ForEach(0..<completedGames.count, id: \.self) { index in
                NavigationLink(destination: PlaySpace(gameId: String(self.completedGames[index].id))) {
                    Text(self.completedGames[index].display())
                }
            }
        }
        .navigationBarTitle("Menu", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: logoutButton)
        .onAppear {
            self.fetchActiveGames()
        }
    }
    
    func fetchActiveGames() {
        let _ = print(self.accessToken.token!.certificate)
        guard let url = URL(string: ROOT_URL + "api/games") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.setValue(self.accessToken.token!.toHttpHeaderString(), forHTTPHeaderField: "Authorization")
        let _ = print(request)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let decodedGames = try? decoder.decode(Games.self, from: data) {
                        self.activeGames = []
                        self.completedGames = []
                        for game in decodedGames.games {
                            if game.completed == nil {
                                self.activeGames.append(game)
                            } else {
                                self.completedGames.append(game)
                            }
                        }
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
        guard let url = URL(string: ROOT_URL + "api/logout") else {
            print("Invalid URL")
            return
        }
        if self.accessToken.isExpired() {
            let (renewed, message) = self.accessToken.renew()
            let _ = print(message)
            if !renewed {
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(self.accessToken.token!.toHttpHeaderString(), forHTTPHeaderField: "Authorization")
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

struct Games: Codable {
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
        var bestPlayer = ""
        var bestScore = -1
        var tie = false
        for gamePlayer in self.game_players {
            displayEntries.append("\(gamePlayer.player.display_name): \(gamePlayer.score)")
            if gamePlayer.score > bestScore {
                bestScore = gamePlayer.score
                bestPlayer = gamePlayer.player.display_name
                tie = false
            } else if gamePlayer.score == bestScore {
                tie = true
            }
        }
        if completed == nil {
            displayEntries.append("\(self.whose_turn_name) to play")
        } else {
            if tie {
                displayEntries.append("It was a draw!")
            }
            displayEntries.append("\(bestPlayer) won!")
        }
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
