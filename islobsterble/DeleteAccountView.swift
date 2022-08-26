//
//  DeleteAccountView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2022-08-24.
//  Copyright © 2022 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let instructions = "Enter your username and password to initiate the account deletion process."
let requestSentMessage = "An account deletion request has been sent. No further action is required."
let incorrectEmailOrPassword = "Incorrect Email or Password"
struct DeleteAccountView: View {
    
    @State private var message = instructions
    @State private var username = ""
    @State private var password = ""
    @State private var requestSent = false
    
    var body: some View {
        VStack {
            Text(self.message).padding()
            HStack {
                Text("Email").padding(.leading, 18)
                Spacer()
            }
            TextField("Email", text: $username)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 18)
            HStack {
                Text("Password").padding(.leading, 18)
                Spacer()
            }
            SecureField("Password", text: $password)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                                HStack {
            
                                    Button(action: { self.requestDeleteAccount() }) {
                    Text("Request Account Deletion")
                }.padding(.leading, 18)
            }.padding(.top, 18)
        }.padding(18).navigationBarTitle("Account Deletion", displayMode: .inline)

    }
    
    func requestDeleteAccount() {
        let authData = AuthData(username: self.username, password: self.password)
        guard let encodedAuthData = try? JSONEncoder().encode(authData) else {
            return
        }
        guard let url = URL(string: ROOT_URL + "api/fresh-token") else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedAuthData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let freshToken = try? decoder.decode(Token.self, from: data) {
                        self.authenticatedRequestAccountDelete(freshToken: freshToken)
                    } else {
                        self.message = "Error decoding token."
                    }
                } else {
                    let error = String(decoding: data, as: UTF8.self)
                    self.message = error
                }
            } else {
                self.message = CONNECTION_ERROR_STR
            }
        }.resume()
    }
    
    private func authenticatedRequestAccountDelete(freshToken: Token) {
        guard let url = URL(string: ROOT_URL + "api/request-account-deletion") else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.addAuthorization(token: freshToken)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.message = requestSentMessage
                } else {
                    let error = String(decoding: data, as: UTF8.self)
                    self.message = error
                }
            } else {
                self.message = CONNECTION_ERROR_STR
            }
        }.resume()
    }
}

struct AuthData: Codable {
    let username: String
    let password: String
}
