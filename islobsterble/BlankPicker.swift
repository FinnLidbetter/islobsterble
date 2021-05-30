//
//  BlankPicker.swift
//  islobsterble
//  View for choosing which letter to use for a placed blank tile.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct BlankPicker: View {
    
    @Binding var isPresented: Bool
    var onSelection: ((Character) -> Void)
    
    let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                ForEach(0..<6) { index in
                    Button(action: {
                        self.onSelection(Character(self.alphabet[index]))
                    }) {
                        Text(self.alphabet[index])
                    }
                    Spacer()
                }
            }
            Spacer()
            HStack {
                Spacer()
                ForEach(6..<12) { index in
                    Button(action: {
                        self.onSelection(Character(self.alphabet[index]))
                    }) {
                        Text(self.alphabet[index])
                    }
                    Spacer()
                }
            }
            Spacer()
            HStack {
                Spacer()
                ForEach(12..<18) { index in
                    Button(action: {
                        self.onSelection(Character(self.alphabet[index]))
                    }) {
                        Text(self.alphabet[index])
                    }
                    Spacer()
                }
            }
            Spacer()
            HStack {
                Spacer()
                ForEach(18..<24) { index in
                    Button(action: {
                        self.onSelection(Character(self.alphabet[index]))
                    }) {
                        Text(self.alphabet[index])
                    }
                    Spacer()
                }
            }
            Spacer()
            HStack {
                Spacer()
                ForEach(24..<26) { index in
                    Button(action: {
                        self.onSelection(Character(self.alphabet[index]))
                    }) {
                        Text(self.alphabet[index])
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .frame(width: SCREEN_SIZE.width * 0.9, height: SCREEN_SIZE.height * 0.3)
        .background(Color(.cyan))
        .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous)).shadow(radius: 6, x: -8, y: -8)
        .offset(y: self.isPresented ? 0 : SCREEN_SIZE.height)
    }
}

