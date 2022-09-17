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
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var accessToken: ManagedAccessToken
    @EnvironmentObject var notificationTracker: NotificationTracker
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loggedIn = false
    @State private var infoMessage = ""
    @State private var showSendEmailVerification = false
    
    
    var registerButton: some View {
        NavigationLink(destination: RegistrationView()) {
            Text("Register").fontWeight(.regular)
        }
    }
    
    var forgotPasswordButton: some View {
        NavigationLink(destination: ForgotPasswordView()) {
            Text("Forgot password?").fontWeight(.regular)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("ReRack").fontWeight(.bold).font(.title)
                HStack {
                    Spacer(minLength: 10)
                    VStack {
                        HStack {
                            Text("Email")
                            Spacer()
                        }
                        TextField("Email", text: $username)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .padding(.bottom, 18)
                        HStack {
                            Text("Password")
                            Spacer()
                        }
                        SecureField("Password", text: $password)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        NavigationLink(destination: GameManagementView(loggedIn: self.$loggedIn).environmentObject(self.accessToken), isActive: self.$loggedIn) {
                            EmptyView()
                        }.isDetailLink(false)
                        HStack {
                            Button(action: { self.login() }) {
                                Text("Login")
                            }.padding(.leading, 18)
                            Spacer()
                            NavigationLink(destination: ForgotPasswordView()) {
                                Text("Forgot password?").fontWeight(.regular)
                            }
                        }.padding(.top, 18)
                        Button(action: { self.resendVerification() }) {
                            Text("Re-send Verification Email")
                        }.allowsHitTesting(self.showSendEmailVerification).opacity(self.showSendEmailVerification ? 1 : 0)
                    }
                    .padding(18)
                    .background(colorScheme == .dark ? .black : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                    Spacer(minLength: 10)
                }
                Text(self.infoMessage)
                Spacer()
            }
            .navigationBarTitle("Login", displayMode: .inline)
            .navigationBarItems(trailing: registerButton)
            .background(RERACK_PRIMARY_COLOR)
        }.onAppear {
            checkSavedCredentials()
        }
    }
    
    func login() {
                
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
                    let userNotificationCenter = UNUserNotificationCenter.current()
                    userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                        if granted {
                            DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                            }
                        }
                    }

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
                            self.showSendEmailVerification = false
                            self.loggedIn = true
                            self.infoMessage = ""
                        } else {
                            self.loggedIn = false
                            self.infoMessage = status.description
                        }
                    } else {
                        self.infoMessage = "Error decoding token."
                    }
                } else {
                    let error = String(decoding: data, as: UTF8.self)
                    self.infoMessage = error
                    if response.statusCode == 401 && error == "Account is not verified" {
                        self.showSendEmailVerification = true
                    }
                }
            } else {
                self.infoMessage = CONNECTION_ERROR_STR
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
        self.infoMessage = ""
        self.loggedIn = true
    }
    
    func resendVerification() {
        guard let url = URL(string: ROOT_URL + "api/send-verification-email") else {
            return
        }
        let verificationData = VerificationData(username: self.username)
        guard let encodedVerificationData = try? JSONEncoder().encode(verificationData) else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedVerificationData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.infoMessage = "Verification email sent."
                } else {
                    let error = String(decoding: data, as: UTF8.self)
                    self.infoMessage = error
                }
            } else {
                self.infoMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
}

struct LoginData: Codable {
    let username: String
    let password: String
    let deviceToken: String?
}

struct VerificationData: Codable {
    let username: String
}
