//
//  SettingsView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let FRIEND_KEY_LENGTH = 15

struct SettingsView: View {
    @State private var displayName: String = ""
    @State private var friendKey: String = ""
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("User Settings")) {
                    HStack {
                        Text("Display name: ")
                        TextField("", text: $displayName)
                    }
                    HStack {
                        Text("Friend key: ")
                        Text(self.friendKey)
                        Spacer()
                        Button(action: self.regenerateFriendKey) {
                            //Image("RegenerateKeyIcon").renderingMode(.original)
                            Text("R")
                        }
                    }
                }
            }.navigationBarTitle("Settings", displayMode: .inline)
            Button(action: self.saveSettings) {
                Text("Save")
            }
        }.onAppear {
            self.getSettings()
        }
    }
    func getSettings() {
        self.displayName = "Player 1"
    }
    func regenerateFriendKey() {
        let characters = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        var newKeyArr: [String] = []
        for _ in 0..<FRIEND_KEY_LENGTH {
            newKeyArr.append(characters[Int.random(in: 0..<characters.count)])
        }
        self.friendKey = newKeyArr.joined(separator: "")
    }
    func saveSettings() {
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
