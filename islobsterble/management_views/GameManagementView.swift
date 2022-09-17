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
    @State private var errorMessages = ObservableQueue<String>()
    @State private var requester: Player = Player(display_name: "", id: -1)
    @State private var activeGames = [GameInfoV2]()
    @State private var completedGames = [GameInfoV2]()
    
    var body: some View {
        ZStack {
            VStack {
                MenuItems(loggedIn: self.$loggedIn, inGame: self.$inGame, selectedGameId: self.$selectedGameId).environmentObject(self.accessToken)
                VStack {
                    if self.selectedGameId != nil {
                        NavigationLink(destination: PlaySpace(gameId: self.$selectedGameId, loggedIn: self.$loggedIn, inGame: self.$inGame).environmentObject(self.accessToken), isActive: self.$inGame) {
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
                                    GameLink(game: self.activeGames[index], requester: self.requester)
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
                                    GameLink(game: self.completedGames[index], requester: self.requester)
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .navigationBarTitle("Menu", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .onAppear {
                self.fetchActiveGames()
            }
            .onChange(of: notificationTracker.refreshGames) { gamesToRefresh in
                if gamesToRefresh.count > 0 {
                    self.fetchActiveGames()
                    self.notificationTracker.refreshGames = []
                }
            }
            .onChange(of: notificationTracker.refreshGameView) { refreshGameView in
                if refreshGameView {
                    self.fetchActiveGames()
                    notificationTracker.setRefreshGameView(value: false)
                }
            }
            .onChange(of: notificationTracker.deviceTokenString) { deviceToken in
                if deviceToken != nil {
                    self.postDeviceToken(deviceToken: deviceToken!)
                }
            }
            ErrorView(errorMessages: self.errorMessages)
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
        request.addValue("v2", forHTTPHeaderField: "Accept-version")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let decodedGames = try? decoder.decode(Games.self, from: data) {
                        self.activeGames = []
                        self.completedGames = []
                        self.requester = decodedGames.requester
                        for game in decodedGames.games {
                            if game.completed == nil {
                                self.activeGames.append(game)
                            } else {
                                self.completedGames.append(game)
                            }
                        }
                        self.activeGames.sort {
                            if $0.whose_turn.player == self.requester {
                                return true
                            }
                            if $1.whose_turn.player == self.requester {
                                return false
                            }
                            return $0.started > $1.started
                        }
                        self.completedGames.sort {
                            $0.completed! > $1.completed!
                        }
                    } else {
                        self.errorMessages.offer(value: "Internal error decoding game management view data.")
                    }
                } else {
                    self.errorMessages.offer(value: "Internal error fetching game management view data.")
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
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
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh data in game management view.")
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for game management view.")
        }
    }
    
    func postDeviceToken(deviceToken: String) {
        let partialPostDeviceTokenRequest = { accessToken in
            postDeviceTokenRequest(renewedAccessToken: accessToken, deviceToken: deviceToken)
        }
        self.accessToken.renewedRequest(successCompletion: partialPostDeviceTokenRequest, errorCompletion: postDeviceTokenErrorCompletion)
    }
    private func postDeviceTokenRequest(renewedAccessToken: Token, deviceToken: String) {
        guard let encodedDeviceToken = try? JSONEncoder().encode(deviceToken) else {
            self.errorMessages.offer(value: "Internal error encoding device token.")
            return
        }
        guard let url = URL(string: ROOT_URL + "api/device-token") else {
            self.errorMessages.offer(value: "Internal error constructing URL for posting the device token.")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedDeviceToken
        request.addAuthorization(token: renewedAccessToken)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
        }.resume()

    }
    func postDeviceTokenErrorCompletion(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh data in game management view.")
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for game management view.")
        }
    }
}
struct MenuItems: View {
    @Binding var loggedIn: Bool
    @Binding var inGame: Bool
    @Binding var selectedGameId: String?
    @EnvironmentObject var accessToken: ManagedAccessToken
    
    var body: some View {
        HStack {
            NavigationLink(destination: SettingsView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                VStack {
                    Image(systemName: "gearshape").font(.system(size: 25.0))
                    Text("Settings").font(.system(size: 14.0))
                }
            }.isDetailLink(false)
            Spacer()
            NavigationLink(destination: StatsView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                VStack {
                    Image(systemName: "chart.bar.xaxis").font(.system(size: 28.0))
                    Text("Stats").font(.system(size: 14.0))
                }
            }.isDetailLink(false)
            Spacer()
            NavigationLink(destination: FriendsView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                VStack {
                    Image(systemName: "person.3").font(.system(size: 25.0))
                    Text("Friends").font(.system(size: 14.0))
                }
            }.isDetailLink(false)
            Spacer()
            NavigationLink(destination: NewGameView(loggedIn: self.$loggedIn, inGame: self.$inGame, selectedGameId: self.$selectedGameId).environmentObject(self.accessToken)) {
                VStack {
                    Image(systemName: "plus").font(.system(size: 25.0))
                    Text("New Game").font(.system(size: 14.0))
                }
            }.isDetailLink(false)
        }
        .padding(.top, 10)
        .padding(.leading, 18)
        .padding(.trailing, 18)
    }
}

struct GameLink: View {
    let game: GameInfoV2
    let requester: Player
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(self.game.headerString(requester: self.requester))
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
    let games: [GameInfoV2]
    let requester: Player
}

struct GameInfoV2: Codable {
    let id: Int
    let game_players: [GamePlayer]
    let whose_turn: GamePlayer
    let started: Date
    let completed: Date?
    
    func headerString(requester: Player) -> String {
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
            if self.whose_turn.player == requester {
                return "Your turn"
            }
            return "\(self.whose_turn.player.display_name)'s turn"
        } else {
            if tie {
                return "It was a draw!"
            } else {
                return "\(bestPlayer) won!"
            }
        }

    }
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
struct Player: Codable, Equatable {
    let display_name: String
    let id: Int
    
    static func ==(lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
}
