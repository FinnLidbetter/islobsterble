//
//  StatsView.swift
//  islobsterble
//  View for displaying player statistics.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct StatsView: View {
    @Binding var loggedIn: Bool
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var wins = 0
    @State private var draws = 0
    @State private var losses = 0
    @State private var bestWordScore = 0
    @State private var bestIndividualGameScore = 0
    @State private var bestCombinedGameScore = 0
    @State private var friendsStats: [FriendData] = []
    @State private var selection: Set<Int> = []
    @State private var errorMessages = ObservableQueue<String>()
    
    var body: some View {
        ZStack {
            List {
                Section(header: Text("Aggregate")) {
                    HStack {
                        Text("Wins: \(self.wins)")
                        Spacer()
                    }
                    HStack {
                        Text("Draws: \(self.draws)")
                        Spacer()
                    }
                    HStack {
                        Text("Losses: \(self.losses)")
                        Spacer()
                    }
                    HStack {
                        Text("Best word score: \(self.bestWordScore)")
                        Spacer()
                    }
                    HStack {
                        Text("Best individual game score: \(self.bestIndividualGameScore)")
                        Spacer()
                    }
                    HStack {
                        Text("Best combined game score: \(self.bestCombinedGameScore)")
                        Spacer()
                    }
                }
                Section(header: Text("Head-to-head")) {
                    ForEach(0..<self.friendsStats.count, id: \.self) { index in
                        HeadToHeadStatsRowView(isExpanded: self.selection.contains(self.friendsStats[index].friendIdentity.player_id),
                                               displayName: self.friendsStats[index].friendIdentity.display_name,
                                               stats: self.friendsStats[index].stats).onTapGesture {
                            self.selectDeselect(index: index, playerId: self.friendsStats[index].friendIdentity.player_id)
                        }
                    }
                }
            }.navigationBarTitle("Stats", displayMode: .inline)
            ErrorView(errorMessages: self.errorMessages)
        }.onAppear {
            self.getStats()
        }
    }
    
    func selectDeselect(index: Int, playerId: Int) {
        if self.selection.contains(playerId) {
            self.selection.remove(playerId)
        } else {
            self.selection.insert(playerId)
            if friendsStats[index].stats == nil {
                self.getHeadToHead(index: index, playerId: playerId)
            }
        }
    }
    
    func getStats() {
        self.accessToken.renewedRequest(successCompletion: self.getStatsRequest, errorCompletion: self.getStatsError)
    }
    
    private func getStatsRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/stats") else {
            self.errorMessages.offer(value: "Internal error constructing the stats URL.")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    if let decodedSettings = try? decoder.decode(StatsSerializer.self, from: data) {
                        self.wins = decodedSettings.wins
                        self.draws = decodedSettings.ties
                        self.losses = decodedSettings.losses
                        self.bestWordScore = decodedSettings.best_word_score
                        self.bestIndividualGameScore = decodedSettings.best_individual_game_score
                        self.bestCombinedGameScore = decodedSettings.best_combined_game_score
                        for friendIdentity in decodedSettings.friends {
                            self.friendsStats.append(FriendData(friendIdentity: friendIdentity, stats: nil))
                        }
                    } else {
                        self.errorMessages.offer(value: "Internal error decoding player stats.")
                    }
                } else {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
        }.resume()
    }
    
    private func getStatsError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh token for getting stats.")
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for getting stats.")
        }
    }
    
    func getHeadToHead(index: Int, playerId: Int) {
        self.accessToken.renewedRequest(successCompletion: self.getHeadToHeadRequest(index: index, playerId: playerId), errorCompletion: self.getHeadToHeadError)
    }
    
    private func getHeadToHeadRequest(index: Int, playerId: Int) -> ((Token) -> ()) {
        return { (token: Token) -> () in
            guard let url = URL(string: ROOT_URL + "api/head-to-head/\(playerId)") else {
                self.errorMessages.offer(value: "Internal error constructing the head-to-head URL.")
                return
            }
            var request = URLRequest(url: url)
            request.addAuthorization(token: token)
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error == nil, let data = data, let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        let decoder = JSONDecoder()
                        if let decodedStats = try? decoder.decode(FriendStatsSerializer.self, from: data) {
                            self.friendsStats[index].stats = decodedStats
                        } else {
                            self.errorMessages.offer(value: "Internal error decoding head-to-head stats.")
                        }
                    } else {
                        self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                    }
                } else {
                    self.errorMessages.offer(value: CONNECTION_ERROR_STR)
                }
            }.resume()
        }
    }
    
    private func getHeadToHeadError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh token for getting head-to-head stats.")
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for getting head-to-head stats.")
        }
    }
}

struct HeadToHeadStatsRowView: View {
    let isExpanded: Bool
    let displayName: String
    let stats: FriendStatsSerializer?
    
    var body: some View {
        VStack {
            HStack {
                Text(self.displayName).fontWeight(.bold)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
            if isExpanded {
                VStack {
                    if let retrievedStats = self.stats {
                        VStack {
                            HStack {
                                Text("Wins: \(retrievedStats.wins)")
                                Spacer()
                            }
                            HStack {
                                Text("Draws: \(retrievedStats.ties)")
                                Spacer()
                            }
                            HStack {
                                Text("Losses: \(retrievedStats.losses)")
                                Spacer()
                            }
                            HStack {
                                Text("Best combined game score: \(retrievedStats.best_combined_game_score)")
                                Spacer()
                            }
                        }
                    } else {
                        Text("Loading...")
                    }
                }.frame(maxWidth: .infinity)
            }
        }.frame(maxWidth: .infinity)
    }
}

struct FriendData {
    let friendIdentity: FriendIdentitySerializer
    var stats: FriendStatsSerializer?
}

struct FriendIdentitySerializer: Codable {
    let display_name: String
    let player_id: Int
}

struct FriendStatsSerializer: Codable {
    let wins: Int
    let ties: Int
    let losses: Int
    let best_combined_game_score: Int
}

struct StatsSerializer: Codable {
    let wins: Int
    let ties: Int
    let losses: Int
    let best_word_score: Int
    let best_individual_game_score: Int
    let best_combined_game_score: Int
    let friends: [FriendIdentitySerializer]
}
