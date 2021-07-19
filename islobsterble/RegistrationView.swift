//
//  RegistrationView.swift
//  islobsterble
//  View for registering a new user.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct RegistrationView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var displayName: String = ""
    @State private var message: String = ""
    @State private var errorMessage: String = ""
    @State private var success = false
    
    var body: some View {
        ZStack {
            VStack {
                Group {
                    Text("Display Name")
                    TextField("Display Name", text: $displayName)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 18)
                        .padding(.trailing, 18)
                        .padding(.bottom, 40)
                    Text("Username")
                    TextField("Username", text: $username)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 18)
                        .padding(.trailing, 18)
                        .padding(.bottom, 40)
                    Text("Password")
                    SecureField("Password", text: $password)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 18)
                        .padding(.trailing, 18)
                    Text(self.password == self.confirmPassword ? "" : "Passwords do not match.")
                    Text("Confirm Password")
                    SecureField("Confirm Password", text: $confirmPassword)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 18)
                        .padding(.trailing, 18)
                }
                Button(action: self.register) {
                    Text("Register")
                }
                .padding(18)
                .disabled(self.password != self.confirmPassword || self.username == "" || self.displayName == "")
                Text(self.message)
            }.navigationBarTitle("Register", displayMode: .inline)
            ErrorView(errorMessage: self.$errorMessage)
        }
    }

    func register() {
        let registrationData = RegistrationData(
            username: self.username,
            password: self.password,
            confirmed_password: self.confirmPassword,
            display_name: self.displayName)
        guard let encodedRegistrationData = try? JSONEncoder().encode(registrationData) else {
            self.errorMessage = "Internal error encoding registration data."
            return
        }
        guard let url = URL(string: ROOT_URL + "api/register") else {
            self.errorMessage = "Internal error constructing registration URL."
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedRegistrationData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.success = true
                    self.message = "Successful registration for user '\(self.username)'."
                } else {
                    self.errorMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.success = false
                self.errorMessage = CONNECTION_ERROR_STR
            }
        }.resume()
    }
}

struct RegistrationData: Codable {
    let username: String
    let password: String
    let confirmed_password: String
    let display_name: String
}
