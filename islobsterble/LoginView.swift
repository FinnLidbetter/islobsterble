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
    @EnvironmentObject var notificationTracker: NotificationTracker
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loggedIn = false
    @State private var failureMessage = ""
    
    
    var registerButton: some View {
        NavigationLink(destination: RegistrationView()) {
            Text("Register").fontWeight(.regular)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                VStack {
                    Text("Username")
                    TextField("Username", text: $username)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 18)
                    Text("Password")
                    SecureField("Password", text: $password)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    NavigationLink(destination: GameManagementView(loggedIn: self.$loggedIn).environmentObject(self.accessToken), isActive: self.$loggedIn) {
                        EmptyView()
                    }.isDetailLink(false)
                    Button(action: { self.login() }) {
                       Text("Login")
                    }.padding(18)
                }.padding(18)
                Spacer()
                Text(self.failureMessage)

            }
            .navigationBarTitle("Login", displayMode: .inline)
            .navigationBarItems(trailing: registerButton)
        }.onAppear {
            checkSavedCredentials()
        }
    }
    
    func login() {
        let userNotificationCenter = UNUserNotificationCenter.current()
        userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            print("Permission granted: \(granted)")
        }
        
        let loginData = LoginData(username: self.username, password: self.password, deviceToken: self.notificationTracker.deviceTokenString)
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
                    } else {
                        self.failureMessage = "Error decoding token."
                    }
                } else {
                    self.failureMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.failureMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }

    func checkSavedCredentials() {
        guard let receivedData = KeyChain.load(location: REFRESH_TAG) else {
            return
        }
        let refreshTokenString = String(decoding: receivedData, as: UTF8.self)
        let refreshToken = Token(keyChainString: refreshTokenString)
        if refreshToken.isExpired() {
            return
        }
        self.failureMessage = ""
        self.loggedIn = true
    }
}

struct LoginData: Codable {
    let username: String
    let password: String
    let deviceToken: String?
}
