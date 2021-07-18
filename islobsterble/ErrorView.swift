//
//  ConnectionErrorView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2021-07-15.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    @Binding var errorMessage: String
    
    var body: some View {
        HStack {
            Text("\(self.errorMessage)")
            Button("x") {
                self.errorMessage = ""
            }.disabled(self.errorMessage == "")
        }
        .padding()
        .frame(width: SCREEN_SIZE.width * 0.9, height: SCREEN_SIZE.height * 0.3)
        .background(Color(.cyan))
        .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous)).shadow(radius: 6, x: -8, y: -8)
        .offset(y: self.errorMessage == "" ? SCREEN_SIZE.height : 0)
    }
}
