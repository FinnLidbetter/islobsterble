//
//  SettingsView.swift
//  islobsterble
//  View for changing player settings.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let FRIEND_KEY_LENGTH = 7
let DEFAULT_DICTIONARY_NAME = "YAWL (Extended)"
let DEFAULT_DICTIONARY_ID = 2

struct SettingsView: View {
    @Binding var loggedIn: Bool
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var displayName: String = ""
    @State private var friendKey: String = ""
    @State private var dictionaryNames = [DEFAULT_DICTIONARY_NAME]
    @State private var dictionaryIDs = [DEFAULT_DICTIONARY_ID]
    @State private var currentDictionaryIndex = 0
    @State private var message: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        ZStack {
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
                                Image(systemName: "arrow.clockwise").renderingMode(.original).font(.system(size: 25.0))
                            }
                        }
                        Picker(selection: $currentDictionaryIndex, label: Text("Dictionary")) {
                            ForEach(0..<self.dictionaryNames.count, id: \.self) { index in
                                Text(self.dictionaryNames[index])
                            }
                        }
                    }
                }.navigationBarTitle("Settings", displayMode: .inline)
                
                Button(action: self.saveSettings) {
                    Text("Save")
                }
                Text(self.message)
                Spacer()
            }.onAppear {
                self.getSettings()
            }
            ErrorView(errorMessage: self.$errorMessage)
        }
    }
    
    func getSettings() {
        self.accessToken.renewedRequest(successCompletion: self.getSettingsRequest, errorCompletion: self.getSettingsError)
    }
    
    private func getSettingsRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/player-settings") else {
            self.errorMessage = "Internal error constructing player settings URL."
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let decodedSettings = try? decoder.decode(SettingsSerializer.self, from: data) {
                        self.displayName = decodedSettings.player.display_name
                        self.friendKey = decodedSettings.player.friend_key
                        self.dictionaryNames = []
                        self.dictionaryIDs = []
                        for dictionaryIndex in 0..<decodedSettings.dictionaries.count {
                            self.dictionaryNames.append(decodedSettings.dictionaries[dictionaryIndex].name)
                            self.dictionaryIDs.append(decodedSettings.dictionaries[dictionaryIndex].id)
                        }
                        self.currentDictionaryIndex = self.dictionaryNames.firstIndex(where: {$0 == decodedSettings.player.dictionary.name}) ?? 0
                    } else {
                        self.errorMessage = "Internal error decoding player settings data."
                    }
                } else {
                    self.errorMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.errorMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func getSettingsError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh token for getting settings."
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for getting settings."
        }
    }
    
    func regenerateFriendKey() {
        let characters = ["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "2", "3", "4", "5", "6", "7", "8", "9"]
        var newKeyArr: [String] = []
        for _ in 0..<FRIEND_KEY_LENGTH {
            newKeyArr.append(characters[Int.random(in: 0..<characters.count)])
        }
        self.friendKey = newKeyArr.joined(separator: "")
    }
    
    func saveSettings() {
        self.accessToken.renewedRequest(successCompletion: self.saveSettingsRequest, errorCompletion: self.saveSettingsError)
    }
    
    private func saveSettingsRequest(token: Token) {
        let settings = PlayerSettingsSerializer(
            display_name: self.displayName, dictionary: DictionarySerializer(id: self.dictionaryIDs[self.currentDictionaryIndex], name: self.dictionaryNames[self.currentDictionaryIndex]), friend_key: self.friendKey)
        guard let encodedSettingsData = try? JSONEncoder().encode(settings) else {
            print("Failed to encode settings data")
            return
        }
        guard let url = URL(string: ROOT_URL + "api/player-settings") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedSettingsData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                
                if response.statusCode == 200 {
                    self.getSettings()
                    self.message = "Settings saved."
                } else {
                    self.errorMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.errorMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func saveSettingsError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh data in saving settings."
        case .keyChainRetrieveError:
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for saving settings."
        }
    }
}

struct SettingsSerializer: Codable {
    let player: PlayerSettingsSerializer
    let dictionaries: [DictionarySerializer]
}
struct PlayerSettingsSerializer: Codable {
    let display_name: String
    let dictionary: DictionarySerializer
    let friend_key: String
    var distribution: SimpleDistributionSerializer? = nil
    var board_layout: SimpleBoardLayoutSerializer? = nil
}
struct DictionarySerializer: Codable {
    let id: Int
    let name: String
}
struct SimpleDistributionSerializer: Codable {
    let id: Int
    let name: String
}
struct SimpleBoardLayoutSerializer: Codable {
    let id: Int
    let name: String
}
