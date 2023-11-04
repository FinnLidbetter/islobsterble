//
//  NewGameView.swift
//  islobsterble
//  View for starting a new game.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let OPPONENTS_MAX = 3

struct NewGameView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var loggedIn: Bool
    @Binding var inGame: Bool
    @Binding var selectedGameId: String?
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var friends: [Friend] = []
    @State private var chosenOpponents: Set<Int> = Set([])
    @State private var errorMessages = ErrorMessageQueue()
    @State private var loading: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Button(action: self.startGame) {
                    Text("Create Game")
                }.disabled(self.chosenOpponents.count == 0 || self.chosenOpponents.count > OPPONENTS_MAX)
                List {
                    ForEach(0..<self.friends.count, id: \.self) { index in
                        Button(action: {
                            if chosenOpponents.contains(index) {
                                chosenOpponents.remove(index)
                            } else {
                                chosenOpponents.insert(index)
                            }
                        }) {
                            Text(self.friends[index].display_name).fontWeight(chosenOpponents.contains(index) ? .heavy : .light)
                        }
                    }
                }
                .navigationBarTitle("New Game", displayMode: .inline)
                .onAppear {
                    self.fetchData()
                }
            }
            ProgressView("Loading..")
                .padding()
                .frame(width: SCREEN_SIZE.width * 0.6, height: SCREEN_SIZE.height * 0.2)
                .background(colorScheme == .dark ? Color(.black) : Color(.cyan))
                .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous)).shadow(radius: 6, x: -8, y: -8)
                .offset(y: self.loading ? 0 : SCREEN_SIZE.height)
            ErrorView(errorMessages: self.errorMessages)
        }
    }
    
    func fetchData() {
        self.accessToken.renewedRequest(successCompletion: self.fetchDataRequest, errorCompletion: self.fetchDataError)
    }
    
    func fetchDataRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/new-game") else {
            self.errorMessages.offer(value: "Internal error constructing new game URL.")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        self.loading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let decodedData = try? JSONDecoder().decode(NewGameFriendsSerializer.self, from: data) {
                        self.friends = decodedData.friends
                    } else {
                        self.errorMessages.offer(value: "Internal error decoding list of friends for new game.")
                        return
                    }
                } else {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
            self.loading = false
        }.resume()
    }
    
    private func fetchDataError(error: RenewedRequestError) {
        print(error)
    }
    
    func startGame() {
        self.accessToken.renewedRequest(successCompletion: self.startGameRequest, errorCompletion: self.startGameError)
    }
    
    private func startGameRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/new-game") else {
            self.errorMessages.offer(value: "Internal error constructing URL for new game request.")
            return
        }
        var chosenFriendIDs = [Int]()
        for friendIndex in self.chosenOpponents {
            chosenFriendIDs.append(self.friends[friendIndex].player_id)
        }
        guard let encodedOpponents = try? JSONSerialization.data(withJSONObject: chosenFriendIDs) else {
            self.errorMessages.offer(value: "Internal error encoding opponents data.")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorization(token: token)
        request.httpMethod = "POST"
        request.httpBody = encodedOpponents
        self.loading = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let newGameId = String(decoding: data, as: UTF8.self)
                    self.selectedGameId = newGameId
                    self.inGame = true
                    self.chosenOpponents = Set([])
                } else {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
            self.loading = false
        }.resume()
    }

    private func startGameError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh data in new game request.")
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for new game request.")
        }
    }
}
struct Friend: Codable {
    let player_id: Int
    let display_name: String
}

struct NewGameFriendsSerializer: Codable {
    let friends: [Friend]
}
