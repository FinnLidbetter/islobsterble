//
//  AddFriendView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct AddFriendView: View {
    @State private var friendKey = ""
    
    var body: some View {
        VStack {
            Text("Friend Key")
            TextField("Enter Friend Key", text: $friendKey)
            Button(action: self.submitAddFriend) {
                Text("Submit")
            }
            Spacer()
        }.navigationBarTitle("Add Friend", displayMode: .inline)
    }
    func submitAddFriend() {
        
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendView()
    }
}
