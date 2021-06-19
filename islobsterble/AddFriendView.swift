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
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var friendKey = ""
    @State private var message = ""
    
    var body: some View {
        VStack {
            Text("Friend Key")
            TextField("Enter Friend Key", text: $friendKey)
            Button(action: self.submitAddFriend) {
                Text("Submit")
            }
            Text(self.message)
            Spacer()
        }.navigationBarTitle("Add Friend", displayMode: .inline)
    }
    func submitAddFriend() {
        self.accessToken.renewedRequest(successCompletion: self.submitAddFriendRequest, errorCompletion: self.addFriendError)
    }
    
    func submitAddFriendRequest(token: Token) {
        guard let encodedFriendKey = try? JSONEncoder().encode(FriendKeySerializer(friend_key: self.friendKey)) else {
            print("Failed to encode data.")
            return
        }
        guard let url = URL(string: ROOT_URL + "api/friends") else {
            print("Invalid URL")
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
                } else {
                    self.message = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.message = "Error: could not connect to the server."
            }
        }.resume()
    }
    private func addFriendError(error: RenewedRequestError) {
        print(error)
    }
}

struct FriendKeySerializer: Codable {
    let friend_key: String
}
