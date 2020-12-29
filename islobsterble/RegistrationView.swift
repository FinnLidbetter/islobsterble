//
//  RegistrationView.swift
//  islobsterble
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
    @State private var success = false
    
    var body: some View {
        VStack {
            Group {
                Text("Username")
                TextField("Username", text: $username)
                Text("Password")
                SecureField("Password", text: $password)
                Text(self.password == self.confirmPassword ? "" : "Passwords do not match.")
                Text("Confirm Password")
                SecureField("Confirm Password", text: $confirmPassword)
                Text("Display Name")
                TextField("Display Name", text: $displayName)
            }
            Button(action: self.register) {
                Text("Register")
            }.disabled(self.password != self.confirmPassword || self.username == "" || self.displayName == "")
            Text(self.message)
        }.navigationBarTitle("Register", displayMode: .inline)
    }
    func register() {
        let registrationData = RegistrationData(
            username: self.username,
            password: self.password,
            confirmed_password: self.confirmPassword,
            display_name: self.displayName)
        guard let encodedRegistrationData = try? JSONEncoder().encode(registrationData) else {
            print("Failed to encode registration data")
            return
        }
        guard let url = URL(string: ROOT_URL + "auth/register") else {
            print("Invalid URL")
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
                }
                self.message = String(decoding: data, as: UTF8.self)
            } else {
                self.success = false
                self.message = "Unknown error"
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
