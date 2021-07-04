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
    @State private var queryWord: String = ""
    @State private var message = ""
    
    var body: some View {
        VStack {
            TextField("", text: $queryWord)
                .background(
                    Rectangle().fill(Color.white).border(Color.black, width: 2))
                .padding()
            Button(action: self.submitQueryWord) {
                Text("Lookup Word")
            }
            Text("\(self.message)")
            // Rack
            // Board
        }
        .navigationBarTitle("Dictionary", displayMode: .inline)
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
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let dictionaryEntry = try? JSONDecoder().decode(DictionaryResponseSerializer.self, from: data) {
                        if dictionaryEntry.word == nil {
                            self.message = "\"\(self.queryWord)\" is not in the dictionary."
                        } else {
                            self.message = "\"\(self.queryWord)\" is a valid word!"
                            if dictionaryEntry.definition != nil {
                                self.message += "\n\(dictionaryEntry.word!): \(dictionaryEntry.definition!)"
                            }
                        }
                    }
                } else {
                    self.message = "Unexpected error."
                }
            } else {
                self.message = "Could not connect to server."
            }
        }.resume()
    }
    
    private func submitQueryWordError(error: RenewedRequestError) {
        self.message = "Token renewal error"
        print(error)
    }
}

struct DictionaryWordSerializer: Codable {
    let word: String
}
struct DictionaryResponseSerializer: Codable {
    let word: String?
    let definition: String?
}
