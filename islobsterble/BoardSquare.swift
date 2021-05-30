//
//  BoardSquare.swift
//  islobsterble
//  View for styling a square on the game board.
//
//  Created by Finn Lidbetter on 2020-12-25.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct BoardSquare: View {
    
    let size: Int
    let letterMultiplier: Int
    let wordMultiplier: Int
    let row: Int
    let column: Int
    
    @EnvironmentObject var boardSlots: SlotGrid
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray)
                .border(Color.black)
            LetterMultiplierShape()
                .fill(self.letterMultiplierColor()).padding(1)
            WordMultiplierShape()
                .fill(self.wordMultiplierColor()).padding(1)
        }
        .frame(width: CGFloat(size), height: CGFloat(size))
        .overlay(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        self.boardSlots.grid[self.row][self.column] = geo.frame(in: .global)
                }
            }
        )
    }
    
    func letterMultiplierColor() -> Color {
        if self.letterMultiplier == 1 {
            return Color.clear
        }
        if self.letterMultiplier == 2 {
            return Color.blue
        }
        if self.letterMultiplier == 3 {
            return Color.purple
        }
        return Color.red
    }
    
    func wordMultiplierColor() -> Color {
        if self.wordMultiplier == 1 {
            return Color.clear
        }
        if self.wordMultiplier == 2 {
            return Color.orange
        }
        if self.wordMultiplier == 3 {
            return Color.red
        }
        return Color.blue
    }
}

struct LetterMultiplierShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rt3 = sqrt(3)
        let factor = CGFloat(rt3 / 2.0)
        let theta = .pi / 6.0
        path.addArc(center: CGPoint(x: rect.minX - factor * rect.width, y: rect.midY), radius: rect.height, startAngle: .radians(-theta), endAngle: .radians(theta), clockwise: false)
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY + factor * rect.height), radius: rect.width, startAngle: .radians(3 * .pi/2 - theta), endAngle: .radians(3 * .pi/2 + theta), clockwise: false)
        path.addArc(center: CGPoint(x: rect.maxX + factor * rect.width, y: rect.midY), radius: rect.height, startAngle: .radians(.pi - theta), endAngle: .radians(.pi + theta), clockwise: false)
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY - factor * rect.height), radius: rect.width, startAngle: .radians(.pi/2 - theta), endAngle: .radians(.pi/2 + theta), clockwise: false)
        return path
    }
}

struct WordMultiplierShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let theta = .pi / 6.0
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .radians(theta), endAngle: .radians(-theta), clockwise: true)
        path.addLine(to: CGPoint(x: rect.midX + rect.width/4.0, y: rect.midY - rect.width/4.0))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .radians((3.0 * .pi / 2.0) + theta), endAngle: .radians((3.0 * .pi / 2.0) - theta), clockwise: true)
        path.addLine(to: CGPoint(x: rect.midX - rect.width/4.0, y: rect.midY - rect.width/4.0))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .radians(.pi + theta), endAngle: .radians(.pi - theta), clockwise: true)
        path.addLine(to: CGPoint(x: rect.midX - rect.width/4.0, y: rect.midY + rect.width/4.0))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .radians((.pi / 2.0) + theta), endAngle: .radians((.pi / 2.0) - theta), clockwise: true)
        path.addLine(to: CGPoint(x: rect.midX + rect.width/4.0, y: rect.midY + rect.width/4.0))
        return path
    }
}
