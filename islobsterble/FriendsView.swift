//
//  FriendsView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct FriendsView: View {
    @State private var myFriendKey = ""
    @State private var friends: [String] = []
    
    var body: some View {
        List {
            Section(header: Text("Friend Key")) {
                Text("\(self.myFriendKey)")
            }
            Section(header: Text("Friends")) {
                List {
                    ForEach(0..<friends.count) { index in
                        Text("\(self.friends[index])")
                    }
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
        self.myFriendKey = ""
        self.friends = []
    }
    
}
