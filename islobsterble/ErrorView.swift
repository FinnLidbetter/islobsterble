//
//  ConnectionErrorView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2021-07-15.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var errorMessages: ErrorMessageQueue
    var body: some View {
        ZStack {
            HStack {
                Text("\(self.errorMessages.isEmpty() ? "" : self.errorMessages.peek()!)")
            }
            VStack {
                HStack {
                    Spacer()
                    Button(action: self.errorMessages.swallowedPoll) {
                        Image(systemName: "clear")
                    }.disabled(self.errorMessages.isEmpty()).padding()
                }
                Spacer()
            }
        }
        .padding()
        .frame(width: SCREEN_SIZE.width * 0.9, height: SCREEN_SIZE.height * 0.3)
        .background(colorScheme == .dark ? Color(.black) : Color(.cyan))
        .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous)).shadow(radius: 6, x: -8, y: -8)
        .offset(y: self.errorMessages.isEmpty() ? SCREEN_SIZE.height : 0)
    }
}
