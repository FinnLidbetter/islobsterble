//
//  DictionaryView.swift
//  islobsterble
//  View for looking up words.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct DictionaryView: View {
    let gameId: String
    
    @EnvironmentObject var accessToken: ManagedAccessToken
    @Binding var loggedIn: Bool
    @Binding var inGame: Bool
    @State private var queryWord: String = ""
    @State private var message = ""
    @State private var errorMessage = ""
    @State private var twoLetterWords: [String] = []
    
    var body: some View {
        VStack {
            HStack {
                Text("Two Letter Words").font(.headline).padding()
                Spacer()
            }
            Text(self.twoLetterWords.count == 0 ? "Loading..." : "\(self.twoLetterWords.joined(separator: " "))").multilineTextAlignment(.center).padding()
            HStack {
                Text("Search").font(.headline).padding()
                Spacer()
            }
            TextField("", text: $queryWord)
                .multilineTextAlignment(.center)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textCase(.lowercase)
                .padding(.all, 18)
            Button(action: self.submitQueryWord) {
                Text("Lookup Word")
            }.disabled(self.queryWord == "")
            Text("\(self.message)")
            // Rack
            // Board
        }
        .navigationBarTitle("Dictionary", displayMode: .inline)
        .onAppear {
            self.fetchTwoLetterWords()
        }
    }
    
    func submitQueryWord() {
        self.accessToken.renewedRequest(successCompletion: self.submitQueryWordRequest, errorCompletion: self.submitQueryWordError)
    }
    
    private func submitQueryWordRequest(token: Token) {
        let invalidCharacters = "[^a-zA-Z]+"
        self.queryWord = self.queryWord.replacingOccurrences(of: invalidCharacters, with: "", options: [.regularExpression])
        self.queryWord = self.queryWord.lowercased()
        guard let url = URL(string: ROOT_URL + "api/game/\(self.gameId)/verify-word/\(self.queryWord)") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        let submittedWord = self.queryWord
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let dictionaryEntry = try? JSONDecoder().decode(DictionaryResponseSerializer.self, from: data) {
                        if dictionaryEntry.word == nil {
                            self.message = "\"\(submittedWord)\" is not in the dictionary."
                        } else {
                            self.message = "\"\(submittedWord)\" is a valid word!"
                            if dictionaryEntry.definition != nil {
                                self.message += "\n\(dictionaryEntry.word!): \(dictionaryEntry.definition!)"
                            }
                        }
                    }
                } else {
                    self.errorMessage = "Internal error in dictionary lookup."
                }
            } else {
                self.message = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func submitQueryWordError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.inGame = false
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh data in dictionary lookup."
        case .keyChainRetrieveError:
            self.inGame = false
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for dictionary lookup."
        }
    }
    
    
    func fetchTwoLetterWords() {
        self.accessToken.renewedRequest(successCompletion: self.fetchTwoLetterWordsRequest, errorCompletion: self.fetchTwoLetterWordsError)
    }
    
    private func fetchTwoLetterWordsRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/game/\(self.gameId)/two-letter-words") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let words = try? JSONDecoder().decode([String].self, from: data) {
                        self.twoLetterWords = words.sorted()
                    }
                } else {
                    self.errorMessage = "Internal error in dictionary lookup."
                }
            } else {
                self.message = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func fetchTwoLetterWordsError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.inGame = false
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessage = CONNECTION_ERROR_STR
            print(sessionError)
        case .decodeError:
            self.errorMessage = "Internal error decoding token refresh data in dictionary lookup."
        case .keyChainRetrieveError:
            self.inGame = false
            self.loggedIn = false
        case .urlError:
            self.errorMessage = "Internal URL error in token refresh for dictionary lookup."
        }
    }
}

struct DictionaryWordSerializer: Codable {
    let word: String
}
struct DictionaryResponseSerializer: Codable {
    let word: String?
    let definition: String?
}
