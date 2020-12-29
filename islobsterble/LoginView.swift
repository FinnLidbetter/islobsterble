//
//  LoginView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var loggedIn = false
    @State private var logoutFailed = false
    @State private var loginFailed = false
    
    
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
                HStack {
                    Button(action: self.logout) {
                        Text("Logout")
                    }.disabled(!self.loggedIn)
                    Button(action: self.login) {
                        Text("Login")
                    }.disabled(self.loggedIn)
                }
                NavigationLink(destination: GameManagementView()) {
                    Text("Enter!")
                }.disabled(!self.loggedIn)
                Text(self.loginFailed ? "Failed to login" : (self.logoutFailed ? "Failed to logout" : ""))
            }.navigationBarTitle("Login", displayMode: .inline)
        }
    }
    
    func login() {
        let loginData = LoginData(username: self.username, password: self.password)
        guard let encodedLoginData = try? JSONEncoder().encode(loginData) else {
            print("Failed to encode login data")
            return
        }
        guard let url = URL(string: ROOT_URL + "auth/login") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedLoginData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.loggedIn = true
                    self.loginFailed = false
                    self.logoutFailed = false
                } else {
                    self.loginFailed = true
                    self.logoutFailed = false
                }
            } else {
                self.loginFailed = true
                self.logoutFailed = false
            }
        }.resume()
    }
    
    func logout() {
        guard let url = URL(string: ROOT_URL + "auth/logout") else {
            print("Invalid URL")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.loggedIn = false
                    self.logoutFailed = false
                    self.loginFailed = false
                } else {
                    self.logoutFailed = true
                    self.loginFailed = false
                }
            } else {
                self.logoutFailed = true
                self.loginFailed = false
            }
        }.resume()
    }
}

struct LoginData: Codable {
    let username: String
    let password: String
}
