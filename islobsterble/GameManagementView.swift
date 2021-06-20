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
                NavigationLink(destination: SettingsView().environmentObject(self.accessToken)) {
                    // Image("SettingsIcon").renderingMode(.original)
                    Text("Settings")
                }
                NavigationLink(destination: StatsView().environmentObject(self.accessToken)) {
                    // Image("StatsIcon").renderingMode(.original)
                    Text("Stats")
                }
                NavigationLink(destination: FriendsView().environmentObject(self.accessToken)) {
                    // Image("ContactsIcon").renderingMode(.original)
                    Text("Friends")
                }
                NavigationLink(destination: NewGameView().environmentObject(self.accessToken)) {
                    // Image("NewGameIcon").renderingMode(.original)
                    Text("New Game")
                }
            }
            List {
                Section(header: Text("Active Games")) {
                    ForEach(0..<activeGames.count, id: \.self) { index in
                        NavigationLink(destination: PlaySpace(gameId: String(self.activeGames[index].id)).environmentObject(self.accessToken)) {
                            VStack {
                                Text(self.activeGames[index].headerString())
                                HStack{
                                    ForEach(0..<activeGames[index].game_players.count, id: \.self) { playerIndex in
                                        Text("\(self.activeGames[index].game_players[playerIndex].player.display_name): \(self.activeGames[index].game_players[playerIndex].score)")
                                        Spacer()
                                    }

                                }
                            }
                        }
                    }
                }
                Section(header: Text("Completed Games")) {
                    
                    ForEach(0..<completedGames.count, id: \.self) { index in
                        NavigationLink(destination: PlaySpace(gameId: String(self.completedGames[index].id)).environmentObject(self.accessToken)) {
                            VStack {
                                Text(self.completedGames[index].headerString())
                                HStack{
                                    ForEach(0..<completedGames[index].game_players.count, id: \.self) { playerIndex in
                                        Text("\(self.completedGames[index].game_players[playerIndex].player.display_name): \(self.completedGames[index].game_players[playerIndex].score)")
                                        Spacer()
                                    }

                                }
                            }
                        }
                    }
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
        self.accessToken.renewedRequest(successCompletion: fetchActiveGamesRequest, errorCompletion: fetchActiveGamesErrorCompletion)
    }
    
    func fetchActiveGamesRequest(renewedAccessToken: Token) {
        let _ = print("In fetch games completion!")
        guard let url = URL(string: ROOT_URL + "api/games") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: renewedAccessToken)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let decodedGames = try? decoder.decode([GameInfo].self, from: data) {
                        self.activeGames = []
                        self.completedGames = []
                        for game in decodedGames {
                            if game.completed == nil {
                                self.activeGames.append(game)
                            } else {
                                self.completedGames.append(game)
                            }
                        }
                    } else {
                        print("Fetch games decoding error")
                    }
                }
            }
        }.resume()
    }
    func fetchActiveGamesErrorCompletion(error: RenewedRequestError) {
        let _ = print("Error!")
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
        self.accessToken.renewedRequest(successCompletion: self.logoutRequest, errorCompletion: self.logoutRenewError)
    }
    
    private func logoutRequest(renewedAccessToken: Token) {
        guard let url = URL(string: ROOT_URL + "api/logout") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addAuthorization(token: renewedAccessToken)
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
    
    private func logoutRenewError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                DispatchQueue.main.async {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        case let .urlSessionError(sessionError):
            print(sessionError)
        case .decodeError:
            print("Decode error")
        case .keyChainRetrieveError:
            DispatchQueue.main.async {
                self.presentationMode.wrappedValue.dismiss()
            }
        case .urlError:
            print("URL error")
        }
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
    var game_players: [GamePlayer]
    let whose_turn_name: String
    let started: Date
    let completed: Date?
    
    func headerString() -> String {
        var bestPlayer = ""
        var bestScore = -1
        var tie = false
        for gamePlayer in self.game_players {
            if gamePlayer.score > bestScore {
                bestScore = gamePlayer.score
                bestPlayer = gamePlayer.player.display_name
                tie = false
            } else if gamePlayer.score == bestScore {
                tie = true
            }
        }
        if completed == nil {
            return "\(self.whose_turn_name)'s turn."
        } else {
            if tie {
                return "It was a draw!"
            } else {
                return "\(bestPlayer) won!"
            }
        }
    }
}
struct GamePlayer: Codable {
    let score: Int
    let player: Player
    let turn_order: Int
}
struct Player: Codable {
    let display_name: String
    let id: Int
}
