//
//  ForgotPasswordView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2022-07-30.
//  Copyright © 2022 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @State private var username: String = ""
    @State private var errorMessages = ObservableQueue<String>()
    @State private var infoMessage: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("Email")
                TextField("Email", text: $username)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.leading, 18)
                    .padding(.trailing, 18)
                    .padding(.bottom, 40)
                Button(action: self.requestPasswordReset) {
                    Text("Request Password Reset")
                }
                .padding(18)
                .disabled(self.username == "")
                Text(self.infoMessage)
                Spacer()
            }.navigationBarTitle("Forgot Password", displayMode: .inline)
            ErrorView(errorMessages: self.errorMessages)
        }

    }
    func requestPasswordReset() {
        let passwordResetRequestData = PasswordResetRequestData(username: self.username)
        guard let encodedData = try? JSONEncoder().encode(passwordResetRequestData) else {
            self.errorMessages.offer(value: "Internal error encoding request data.")
            return
        }
        guard let url = URL(string: ROOT_URL + "api/request-password-reset") else {
            self.errorMessages.offer(value: "Internal error constructing request password reset URL.")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encodedData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.infoMessage = "Password reset link sent to '\(self.username)'."
                } else {
                    self.infoMessage = String(decoding: data, as: UTF8.self)
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
        }.resume()
    }
}

struct PasswordResetRequestData: Codable {
    let username: String
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
