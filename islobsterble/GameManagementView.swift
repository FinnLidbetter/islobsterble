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
    @EnvironmentObject var notificationTracker: NotificationTracker
    @Binding var loggedIn: Bool
    @State private var selectedGameId: String? = nil
    @State private var inGame: Bool = false
    @State private var errorMessage = ""
    @State private var activeGames = [GameInfo]()
    @State private var completedGames = [GameInfo]()
    
    var body: some View {
        ZStack {
            VStack {
                MenuItems(loggedIn: self.$loggedIn).environmentObject(self.accessToken)
                VStack {
                    if self.selectedGameId != nil {
                        NavigationLink(destination: PlaySpace(gameId: self.selectedGameId!, loggedIn: self.$loggedIn, inGame: self.$inGame).environmentObject(self.accessToken), isActive: self.$inGame) {
                            EmptyView()
                        }.isDetailLink(false)
                    }
                }.hidden()
                List {
                    Section(header: Text("Active Games")) {
                        ForEach(0..<activeGames.count, id: \.self) { index in
                            Button(
                                action: {
                                    self.selectedGameId = String(self.activeGames[index].id)
                                    self.inGame = true
                                }){
                                GameLink(game: self.activeGames[index])
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                    Section(header: Text("Completed Games")) {
                        ForEach(0..<completedGames.count, id: \.self) { index in
                            Button(
                                action: {
                                    self.selectedGameId = String(self.completedGames[index].id)
                                    self.inGame = true
                                }){
                                GameLink(game: self.completedGames[index])
                            }.buttonStyle(PlainButtonStyle())
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
            .onChange(of: notificationTracker.refreshGames) { gamesToRefresh in
                if gamesToRefresh.count > 0 {
                    self.fetchActiveGames()
                    self.notificationTracker.refreshGames = []
                }
            }
            ErrorView(errorMessage: self.$errorMessage)
        }
    }
    
    func fetchActiveGames() {
        self.accessToken.renewedRequest(successCompletion: fetchActiveGamesRequest, errorCompletion: fetchActiveGamesErrorCompletion)
    }
    
    func fetchActiveGamesRequest(renewedAccessToken: Token) {
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
                        self.activeGames.sort {
                            $0.started > $1.started
                        }
                        self.completedGames.sort {
                            $0.completed! > $1.completed!
                        }
                    } else {
                        self.errorMessage = "Internal error decoding game management view data."
                    }
                } else {
                    self.errorMessage = "Internal error fetching game management view data."
                }
            } else {
                self.errorMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    func fetchActiveGamesErrorCompletion(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh data in game management view."
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for game management view."
        }
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
                    self.loggedIn = false
                } else {
                    self.errorMessage = "Unexpected internal logout error."
                }
            } else {
                self.errorMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func logoutRenewError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh data in logging out."
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for logout."
        }
    }
}
struct MenuItems: View {
    @Binding var loggedIn: Bool
    @EnvironmentObject var accessToken: ManagedAccessToken
    
    var body: some View {
        HStack {
            NavigationLink(destination: SettingsView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                // Image("SettingsIcon").renderingMode(.original)
                Text("Settings")
            }.isDetailLink(false)
            Spacer()
            NavigationLink(destination: StatsView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                // Image("StatsIcon").renderingMode(.original)
                Text("Stats")
            }.isDetailLink(false)
            Spacer()
            NavigationLink(destination: FriendsView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                // Image("ContactsIcon").renderingMode(.original)
                Text("Friends")
            }.isDetailLink(false)
            Spacer()
            NavigationLink(destination: NewGameView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                // Image("NewGameIcon").renderingMode(.original)
                Text("New Game")
            }.isDetailLink(false)
        }
        .padding(.top, 10)
        .padding(.leading, 18)
        .padding(.trailing, 18)
    }
}

struct GameLink: View {
    let game: GameInfo
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.game.headerString())
            HStack{
                Spacer()
                ForEach(0..<self.game.game_players.count, id: \.self) { playerIndex in
                    Text("\(self.game.game_players[playerIndex].player.display_name): \(self.game.game_players[playerIndex].score)")
                    Spacer()
                }

            }
        }
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
            return "\(self.whose_turn_name)'s turn"
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
