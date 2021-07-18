//
//  AddFriendView.swift
//  islobsterble
//  View for adding a new friend.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct AddFriendView: View {
    @Binding var loggedIn: Bool
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var friendKey = ""
    @State private var message = ""
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            VStack {
                Text("Friend Key")
                TextField("Enter Friend Key", text: $friendKey)
                Button(action: self.submitAddFriend) {
                    Text("Submit")
                }
                Spacer()
                Text(self.message)
            }.navigationBarTitle("Add Friend", displayMode: .inline)
            ErrorView(errorMessage: self.$errorMessage)
        }
    }
    func submitAddFriend() {
        self.accessToken.renewedRequest(successCompletion: self.submitAddFriendRequest, errorCompletion: self.addFriendError)
    }
    
    func submitAddFriendRequest(token: Token) {
        guard let encodedFriendKey = try? JSONEncoder().encode(FriendKeySerializer(friend_key: self.friendKey)) else {
            self.errorMessage = "Internal error encoding friend key."
            return
        }
        guard let url = URL(string: ROOT_URL + "api/friends") else {
            self.errorMessage = "Internal error constructing URL for adding friends."
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedFriendKey
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.message = "Success"
                    self.friendKey = ""
                } else {
                    self.errorMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.errorMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func addFriendError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh data in add friends view."
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for add friends data submission."
        }
    }
}

struct FriendKeySerializer: Codable {
    let friend_key: String
}
