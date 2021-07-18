//
//  ExchangePicker.swift
//  islobsterble
//  View for choosing which letters to exchange.
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ExchangePicker: View {
    @Binding var isPresented: Bool
    var rackLetters: [Letter]
    @Binding var chosen: [Bool]
    var onSelectTile: (Int) -> Void
    var onExchange: () -> Void
    
    var body: some View {
        VStack {
            Text("Select Tiles to Exchange")
            HStack {
                Spacer()
                ForEach(0..<NUM_RACK_TILES) { index in
                    Button(action: {
                        self.onSelectTile(index)
                    }) {
                        Tile(size: Int(SCREEN_SIZE.width * 0.7) / NUM_RACK_TILES,
                             face: self.rackLetters[index],
                             position: Position(boardRow: nil, boardColumn: nil, rackIndex: nil),
                             allowDrag: false,
                             onChanged: dummyOnChanged,
                             onEnded: dummyOnEnded
                        )
                        .opacity(self.chosen[index] ? 0.2 : 1.0)
                    }
                }
                Spacer()
            }
            HStack {
                Button(action: {
                    self.onCancel()
                }) {
                    Text("Cancel")
                }
                // Exchange button.
                Button(action: {
                    self.onExchange()
                }) {
                    Text("Exchange")
                }.disabled(!chosen.contains(true))
            }
        }
        .padding()
        .frame(width: SCREEN_SIZE.width * 0.9, height: SCREEN_SIZE.height * 0.3)
        .background(Color(.cyan))
        .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous)).shadow(radius: 6, x: -8, y: -8)
        .offset(y: self.isPresented ? 0 : SCREEN_SIZE.height)
    }
    
    func onCancel() {
        self.chosen = [Bool](repeating: false, count: NUM_RACK_TILES)
        self.isPresented = false
    }
}
func dummyOnChanged(dummyPoint: CGPoint, dummyLetter: Letter, dummyPosition: Position) -> Position {
    return Position(boardRow: nil, boardColumn: nil, rackIndex: nil)
}
func dummyOnEnded(dummyLetter: Letter, dummyPosition1: Position, dummyPosition2: Position) {
    return
}

