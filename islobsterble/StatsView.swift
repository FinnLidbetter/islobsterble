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
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Wins: \(self.wins)").padding()
                    Spacer()
                    Text("Draws: \(self.draws)").padding()
                    Spacer()
                    Text("Losses: \(self.losses)").padding()
                }
                HStack {
                    Text("Best word score: \(self.bestWordScore)").padding()
                    Spacer()
                }
                HStack {
                    Text("Best individual game score: \(self.bestIndividualGameScore)").padding()
                    Spacer()
                }
                HStack {
                    Text("Best combined game score: \(self.bestCombinedGameScore)").padding()
                    Spacer()
                }
                Spacer()
            }.navigationBarTitle("Stats", displayMode: .inline)
            ErrorView(errorMessage: self.$errorMessage)
        }.onAppear {
            self.getStats()
        }
    }
    
    func getStats() {
        self.accessToken.renewedRequest(successCompletion: self.getStats, errorCompletion: self.getStatsError)
    }
    
    private func getStats(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/stats") else {
            self.errorMessage = "Internal error constructing the stats URL."
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
                    } else {
                        self.errorMessage = "Internal error decoding player stats."
                    }
                } else {
                    self.errorMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.errorMessage = CONNECTION_ERROR_STR
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
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh token for getting stats."
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for getting stats."
        }
    }
}
struct StatsSerializer: Codable {
    let wins: Int
    let ties: Int
    let losses: Int
    let best_word_score: Int
    let best_individual_game_score: Int
    let best_combined_game_score: Int
}
