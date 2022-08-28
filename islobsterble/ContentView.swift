//
//  ContentView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-03.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let RERACK_PRIMARY_COLOR = Color(red: 102 / 255, green: 180 / 255, blue: 249 / 255)

struct ContentView: View {
    @ObservedObject var accessToken: ManagedAccessToken = ManagedAccessToken()
    
    var body: some View {
        LoginView().environmentObject(accessToken).environment(\.sizeCategory, .large)
    }
}
