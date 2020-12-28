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
    
    var body: some View {
        VStack {
            Text("Username")
            TextField("Username", text: $username)
            Text("Password")
            SecureField("Password", text: $password)
            Text("Confirm Password")
            SecureField("Confirm Password", text: $confirmPassword)
            Text("Display Name")
            TextField("Display Name", text: $displayName)
            Button(action: self.register) {
                Text("Register")
            }
        }.navigationBarTitle("Register", displayMode: .inline)
    }
    func register() {
        
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
