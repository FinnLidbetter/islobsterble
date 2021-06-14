//
//  LoginView.swift
//  islobsterble
//  View for authenticating the user.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var accessToken: ManagedAccessToken
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loggedIn = false
    @State private var failureMessage = ""
    
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    NavigationLink(destination: RegistrationView()) {
                        Text("Register")
                    }
                }
                Text("Username")
                TextField("Username", text: $username)
                Text("Password")
                SecureField("Password", text: $password)
                NavigationLink(destination: GameManagementView().environmentObject(self.accessToken), isActive: $loggedIn) {
                    EmptyView()
                }
                Button(action: { self.login() }) {
                   Text("Login")
                }
                Text(self.failureMessage)
            }.navigationBarTitle("Login", displayMode: .inline)
        }
    }
    
    func login() {
        let loginData = LoginData(username: self.username, password: self.password)
        guard let encodedLoginData = try? JSONEncoder().encode(loginData) else {
            return
        }
        guard let url = URL(string: ROOT_URL + "api/login") else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedLoginData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .secondsSince1970
                    if let tokenPair = try? decoder.decode(TokenPair.self, from: data) {
                        DispatchQueue.main.async {
                            accessToken.token = tokenPair.access_token
                        }
                        let refreshToken = tokenPair.refresh_token
                        
                        let valueToStore = refreshToken.toKeyChainString()
                        
                        let status = KeyChain.save(location: REFRESH_TAG, value: valueToStore)
                        if status == noErr {
                            self.loggedIn = true
                            self.failureMessage = ""
                        } else {
                            self.loggedIn = false
                            self.failureMessage = status.description
                        }
                    }
                } else {
                    self.failureMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.failureMessage = "Could not connect to the server."
            }
        }.resume()
    }
}

struct LoginData: Codable {
    let username: String
    let password: String
}
