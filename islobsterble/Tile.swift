//
//  Tile.swift
//  islobsterble
//  View for the behaviour and styling of tiles.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct Tile: View {
    @State private var dragAmount = CGSize.zero
    @State private var dragState = Position(boardRow: nil, boardColumn: nil, rackIndex: nil)
    
    let size: Int
    let face: Letter
    let position: Position
    let allowDrag: Bool
    var onChanged: ((CGPoint, Letter, Position) -> Position)
    var onEnded: ((Letter, Position, Position) -> Void)
    
    var body: some View {
        Text(self.face.letter == BLANK ? "" : String(self.face.letter))
            .foregroundColor(self.face.is_blank ? Color.red : Color.black)
            .frame(width: CGFloat(self.size), height: CGFloat(self.size))
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(self.face == INVISIBLE_LETTER ? Color(.clear) : Color(.yellow))
            )
            .offset(self.dragAmount)
            .zIndex(self.dragAmount == .zero ? 0 : 1)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { gesture in
                        self.dragAmount = self.allowDrag ? gesture.translation : .zero
                        self.dragState = self.onChanged(gesture.location, self.face, self.position)
                    }
                .onEnded { gesture in
                    self.dragAmount = .zero
                    self.onEnded(self.face, self.position, self.dragState)
                }
            )
    }
    
    func isInvisible() -> Bool {
        return self.face == INVISIBLE_LETTER
    }
}
