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
    @State private var myFriendKey = ""
    @State private var friends: [String] = []
    @State private var message = ""
    
    var body: some View {
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
                NavigationLink(destination: AddFriendView()) {
                    // Image(AddFriendIcon)
                    Text("Add Friend")
                }
        )
        .onAppear {
            self.fetchData()
        }
    }
    func fetchData() {
        guard let url = URL(string: ROOT_URL + "api/friends") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
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
}

struct FriendsDataSerializer: Codable {
    let friend_key: String
    let friends: [FriendSerializer]
}
struct FriendSerializer: Codable {
    let display_name: String
    let player_id: Int
}
