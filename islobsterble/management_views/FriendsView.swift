//
//  FriendsView.swift
//  islobsterble
//  View for managing friends.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct FriendsView: View {
    @Binding var loggedIn: Bool
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var myFriendKey = ""
    @State private var friends: [String] = []
    @State private var errorMessages = ErrorMessageQueue()
    
    var body: some View {
        ZStack {
            List {
                Section(header: Text("Friend Key")) {
                    Text("\(self.myFriendKey)")
                }
                Section(header: Text("Friends")) {
                    ForEach(0..<self.friends.count, id: \.self) { index in
                        Text("\(self.friends[index])")
                    }
                }
            }
            .navigationBarTitle("Friends", displayMode: .inline)
            .navigationBarItems(
                trailing:
                    NavigationLink(destination: AddFriendView(loggedIn: self.$loggedIn).environmentObject(self.accessToken)) {
                        // Image(AddFriendIcon)
                        Text("Add Friend")
                    }
            )
            .onAppear {
                self.fetchData()
            }
            ErrorView(errorMessages: self.errorMessages)
        }
    }
    func fetchData() {
        self.accessToken.renewedRequest(successCompletion: self.fetchDataRequest, errorCompletion: self.fetchDataError)
    }
    
    func fetchDataRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/friends") else {
            self.errorMessages.offer(value: "Internal error constructing Friends API URL.")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let decodedData = try? JSONDecoder().decode(FriendsDataSerializer.self, from: data) {
                        self.myFriendKey = decodedData.friend_key
                        self.friends = []
                        for friendIndex in 0..<decodedData.friends.count {
                            self.friends.append(decodedData.friends[friendIndex].display_name)
                        }
                    } else {
                        self.errorMessages.offer(value: "Internal error decoding friends data.")
                        return
                    }
                } else {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
        }.resume()
    }
    private func fetchDataError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh data in friends view.")
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for friends data fetch.")
        }
    }
}

struct FriendsDataSerializer: Codable {
    let friend_key: String
    let friends: [FriendSerializer]
}
struct FriendSerializer: Codable {
    let display_name: String
    let player_id: Int
}
