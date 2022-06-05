//
//  PassConfirmer.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2022-06-05.
//  Copyright © 2022 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct PassConfirmer: View {
    @Binding var isPresented: Bool
    var onPassConfirm: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Text("Do you want to pass your turn?")
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    self.onCancel()
                }) {
                    Text("Cancel")
                }
                Spacer()
                // Pass button.
                Button(action: {
                    self.isPresented = false
                    self.onPassConfirm()
                }) {
                    Text("Pass")
                }
                Spacer()
            }
            Spacer()
        }
        .padding()
        .frame(width: SCREEN_SIZE.width * 0.9, height: SCREEN_SIZE.height * 0.3)
        .background(Color(.cyan))
        .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous)).shadow(radius: 6, x: -8, y: -8)
        .offset(y: self.isPresented ? 0 : SCREEN_SIZE.height)
    }
    
    func onCancel() {
        self.isPresented = false
    }
}

