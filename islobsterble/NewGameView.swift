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
    @Binding var loggedIn: Bool
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var friends: [Friend] = []
    @State private var chosenOpponents: Set<Int> = Set([])
    @State private var message = ""
    
    var body: some View {
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
    
    func fetchData() {
        self.accessToken.renewedRequest(successCompletion: self.fetchDataRequest, errorCompletion: self.fetchDataError)
    }
    
    func fetchDataRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/new-game") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let decodedData = try? JSONDecoder().decode(NewGameFriendsSerializer.self, from: data) {
                        self.friends = decodedData.friends
                        print(self.friends)
                    } else {
                        print("Error decoding data")
                        return
                    }
                } else {
                    self.message = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.message = "Could not connect to the server."
            }
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
            print("Invalid URL")
            return
        }
        var chosenFriendIDs = [Int]()
        for friendIndex in self.chosenOpponents {
            chosenFriendIDs.append(self.friends[friendIndex].player_id)
        }
        guard let encodedOpponents = try? JSONSerialization.data(withJSONObject: chosenFriendIDs) else {
            print("Failed to encode friend ids")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorization(token: token)
        request.httpMethod = "POST"
        request.httpBody = encodedOpponents
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.chosenOpponents = Set([])
                }
                self.message = String(decoding: data, as: UTF8.self)
            } else {
                self.message = "Error: could not connect to the server."
            }
        }.resume()
    }

    private func startGameError(error: RenewedRequestError) {
        print(error)
    }
}
struct Friend: Codable {
    let player_id: Int
    let display_name: String
}

struct NewGameFriendsSerializer: Codable {
    let friends: [Friend]
}
