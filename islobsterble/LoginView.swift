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
    @State private var loggedIn = true
    
    
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
            }.navigationBarTitle("Login", displayMode: .inline)
        }
    }
    func login() {
        
    }
    func logout() {
        
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
