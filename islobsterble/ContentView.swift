//
//  ContentView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-03.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let screenSize: CGRect = UIScreen.main.bounds

let BLANK = Character("-")
let INVISIBLE = Character(" ")
let INVISIBLE_LETTER = Letter(letter: INVISIBLE, is_blank: false)
let NUM_RACK_TILES = 7
let NUM_BOARD_ROWS = 15
let NUM_BOARD_COLUMNS = 15

struct ContentView: View {
    @EnvironmentObject var boardSlots: SlotGrid
    @EnvironmentObject var rackSlots: SlotRow
    
    var body: some View {
        VStack {
            PlaySpace(width: Int(screenSize.width))
        }
    }
}
func dummy(location: CGPoint, letter: Letter) {
    
}

var previewBoardSlots = SlotGrid(num_rows: NUM_BOARD_ROWS, num_columns: NUM_BOARD_COLUMNS)
var previewRackSlots = SlotRow(num_slots: NUM_RACK_TILES)

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(previewBoardSlots).environmentObject(previewRackSlots)
    }
}

func initial_letters() -> [Letter] {
    var rackLetters: [Letter] = []
    rackLetters.append(Letter(letter: Character("A"), is_blank: false))
    rackLetters.append(Letter(letter: Character("B"), is_blank: false))
    rackLetters.append(Letter(letter: Character("C"), is_blank: false))
    rackLetters.append(Letter(letter: Character("D"), is_blank: false))
    rackLetters.append(Letter(letter: Character("E"), is_blank: false))
    rackLetters.append(Letter(letter: Character("F"), is_blank: false))
    rackLetters.append(Letter(letter: Character("-"), is_blank: true))
    return rackLetters
}

enum FrontTaker {
    case unknown
    case board
    case rack
}

struct PlaySpace: View {
    let width: Int
    @State private var boardLetters = [[Letter]](repeating: [Letter](repeating: INVISIBLE_LETTER, count: NUM_BOARD_COLUMNS), count: NUM_BOARD_ROWS)
    @State private var locked = [[Bool]](repeating: [Bool](repeating: false, count: NUM_BOARD_COLUMNS), count: NUM_BOARD_ROWS)
    @State private var rackLetters: [Letter] = initial_letters()
    @State private var rackShuffleState: [Letter] = [Letter](repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
    @State private var frontTaker: FrontTaker = FrontTaker.unknown
    
    @EnvironmentObject var boardSlots: SlotGrid
    @EnvironmentObject var rackSlots: SlotRow
    
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                BoardBackground(boardSquares: setupBoardSquares())
                RackBackground(rackSquares: setupRackSquares())
            }
            VStack(spacing: 20) {
                BoardForeground(tiles: setupBoardTiles()).zIndex(self.frontTaker == FrontTaker.board ? 1 : 0)
                RackForeground(tiles: setupRackTiles(), shuffleState: setupShuffleState()).zIndex(self.frontTaker == FrontTaker.rack ? 1 : 0)
            }
        }
    }
    
    func nearestEmpty(newIndex: Int, originalIndex: Int?) -> Int {
        for delta in 0..<NUM_RACK_TILES {
            if newIndex + delta < NUM_RACK_TILES {
                if newIndex + delta == originalIndex {
                    if self.rackShuffleState[newIndex + delta] == INVISIBLE_LETTER {
                        return newIndex + delta
                    }
                } else {
                    if self.rackLetters[newIndex + delta] == INVISIBLE_LETTER {
                        return newIndex + delta
                    }
                }
            }
            if newIndex - delta >= 0 {
                if newIndex - delta == originalIndex {
                    if self.rackShuffleState[newIndex - delta] == INVISIBLE_LETTER {
                        return newIndex - delta
                    }
                } else {
                    if self.rackLetters[newIndex - delta] == INVISIBLE_LETTER {
                        return newIndex - delta
                    }
                }
            }
        }
        return -1
    }
    
    
    func readDragIndex(index: Int, originalIndex: Int?) -> Letter {
        if originalIndex != nil && index == originalIndex! {
            return self.rackShuffleState[index]
        }
        return self.rackLetters[index]
    }
    func setDragIndex(index: Int, originalIndex: Int?, letter: Letter) {
        if originalIndex != nil && index == originalIndex! {
            self.rackShuffleState[index] = letter
        } else {
            self.rackLetters[index] = letter
        }
    }
    
    
    func shiftRack(newIndex: Int, originalIndex: Int?) {
        let nearestEmptyIndex = nearestEmpty(newIndex: newIndex, originalIndex: originalIndex)
        
        var start = newIndex + 1
        let end = nearestEmptyIndex
        var step = 1
        if newIndex > nearestEmptyIndex {
            start = newIndex - 1
            step = -1
        }
        var prevLetter = readDragIndex(index: newIndex, originalIndex: originalIndex)
        setDragIndex(index: newIndex, originalIndex: originalIndex, letter: INVISIBLE_LETTER)
        for index in stride(from: start, through: end, by: step) {
            let tmpLetter = readDragIndex(index: index, originalIndex: originalIndex)
            setDragIndex(index: index, originalIndex: originalIndex, letter: prevLetter)
            prevLetter = tmpLetter
        }
    }
    
    func tileMoved(location: CGPoint, letter: Letter, position: Position) -> Position {
        // Make sure that the tile being dragged is always at the front.
        if position.rackIndex != nil {
            self.frontTaker = FrontTaker.rack
        } else if position.boardRow != nil {
            self.frontTaker = FrontTaker.board
        }
        for rackIndex in 0..<NUM_RACK_TILES {
            if self.rackSlots.slots[rackIndex].contains(location) {
                shiftRack(newIndex: rackIndex, originalIndex: position.rackIndex)
                return Position(boardRow: nil, boardColumn: nil, rackIndex: rackIndex)
            }
        }
        for row in 0..<NUM_BOARD_ROWS {
            for column in 0..<NUM_BOARD_COLUMNS {
                if boardSlots.grid[row][column].contains(location) {
                    return Position(boardRow: row, boardColumn: column, rackIndex: nil)
                }
            }
        }
        return Position(boardRow: nil, boardColumn: nil, rackIndex: nil)
    }
    func tileDropped(letter: Letter, startPosition: Position, endPosition: Position) {
        self.frontTaker = FrontTaker.unknown
        if endPosition.boardRow != nil && endPosition.boardColumn != nil {
            if startPosition.rackIndex != nil {
                self.rackLetters[startPosition.rackIndex!] = INVISIBLE_LETTER
            } else {
                self.boardLetters[startPosition.boardRow!][startPosition.boardColumn!] = INVISIBLE_LETTER
            }
            self.boardLetters[endPosition.boardRow!][endPosition.boardColumn!] = letter
        } else if endPosition.rackIndex != nil {
            if startPosition.rackIndex != nil {
                self.rackLetters[startPosition.rackIndex!] = INVISIBLE_LETTER
                self.rackLetters[endPosition.rackIndex!] = letter
            }
            if startPosition.boardRow != nil && startPosition.boardColumn != nil {
                self.boardLetters[startPosition.boardRow!][startPosition.boardColumn!] = INVISIBLE_LETTER
                self.rackLetters[endPosition.rackIndex!] = letter
            }
        }
        for index in 0..<NUM_RACK_TILES {
            if self.rackShuffleState[index] != INVISIBLE_LETTER {
                self.rackLetters[index] = self.rackShuffleState[index]
            }
        }
        self.rackShuffleState = [Letter](repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
    }
    
    private func setupBoardTiles() -> [[Tile]] {
        var boardTiles: [[Tile]] = []
        for row in 0..<NUM_BOARD_ROWS {
            var boardRow: [Tile] = []
            for column in 0..<NUM_BOARD_COLUMNS {
                boardRow.append(Tile(
                    size: self.width / NUM_BOARD_COLUMNS,
                    face: boardLetters[row][column],
                    position: Position(boardRow: row, boardColumn: column, rackIndex: nil),
                    onChanged: self.tileMoved,
                    onEnded: self.tileDropped
                ))
            }
            boardTiles.append(boardRow)
        }
        return boardTiles
    }
    
    private func setupBoardSquares() -> [[BoardSquare]] {
        let colors = getBoardColors()
        var boardSquares: [[BoardSquare]] = []
        let size = self.width / NUM_BOARD_COLUMNS
        for row in 0..<NUM_BOARD_ROWS {
            var boardSquareRow: [BoardSquare] = []
            for column in 0..<NUM_BOARD_COLUMNS {
                boardSquareRow.append(BoardSquare(size: size, color: colors[row][column], row: row, column: column))
            }
            boardSquares.append(boardSquareRow)
        }
        return boardSquares
    }
    func getBoardColors() -> [[Color]] {
        var colors = Array(repeating: Array(repeating: Color.gray, count: 15), count: 15)
        colors[0][0] = Color.red
        colors[0][7] = Color.red
        colors[0][14] = Color.red
        colors[7][0] = Color.red
        colors[7][7] = Color.orange
        colors[7][14] = Color.red
        colors[14][0] = Color.red
        colors[14][7] = Color.red
        colors[14][14] = Color.red
        return colors
    }
    
    private func setupRackTiles() -> [Tile] {
        var rackTiles: [Tile] = []
        for index in 0..<NUM_RACK_TILES {
            rackTiles.append(Tile(
                    size: self.width / NUM_RACK_TILES,
                    face: self.rackLetters[index],
                    position: Position(boardRow: nil, boardColumn: nil, rackIndex: index),
                    onChanged: self.tileMoved,
                    onEnded: self.tileDropped))
        }
        return rackTiles
    }
    private func setupShuffleState() -> [Tile] {
        var shuffleTiles: [Tile] = []
        for index in 0..<NUM_RACK_TILES {
            shuffleTiles.append(Tile(
                size: self.width / NUM_RACK_TILES,
                face: self.rackShuffleState[index],
                position: Position(boardRow: nil, boardColumn: nil, rackIndex: index),
                onChanged: self.tileMoved,
                onEnded: self.tileDropped))
        }
        return shuffleTiles
    }
    
    private func setupRackSquares() -> [RackSquare] {
        var rackSquares: [RackSquare] = []
        for index in 0..<NUM_RACK_TILES {
            rackSquares.append(RackSquare(size: self.width / NUM_RACK_TILES, color: Color.green, index: index))
        }
        return rackSquares
    }
    
}

struct Letter: Equatable {
    let letter: Character
    let is_blank: Bool
    let value: Int?
    
    init(letter: Character, is_blank: Bool) {
        self.letter = letter
        self.is_blank = is_blank
        self.value = nil
    }
    static func ==(lhs: Letter, rhs: Letter) -> Bool {
        return lhs.letter == rhs.letter && lhs.is_blank == rhs.is_blank && lhs.value == rhs.value
    }
}

struct Position {
    let boardRow: Int?
    let boardColumn: Int?
    let rackIndex: Int?
}

struct Tile: View {
    @State private var dragAmount = CGSize.zero
    @State private var dragState = Position(boardRow: nil, boardColumn: nil, rackIndex: nil)
    
    let size: Int
    let face: Letter
    let position: Position
    var onChanged: ((CGPoint, Letter, Position) -> Position)
    var onEnded: ((Letter, Position, Position) -> Void)
    
    
    var body: some View {
        Text(self.face.is_blank ? "" : String(self.face.letter))
            .frame(width: CGFloat(self.size), height: CGFloat(self.size))
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(self.face == INVISIBLE_LETTER ? Color(.clear) : Color(.yellow))
            )
            .offset(self.dragAmount)
            .zIndex(self.dragAmount == .zero ? 0 : 1)
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { gesture in
                        self.dragAmount = gesture.translation
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

struct RackSquare: View {
    let size: Int
    let color: Color
    let index: Int
    @EnvironmentObject var rackSlots: SlotRow
 
    var body: some View {
        Rectangle()
            .fill(self.color)
            .frame(width: CGFloat(self.size), height: CGFloat(self.size))
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            self.rackSlots.slots[self.index] = geo.frame(in: .global)
                    }
                }
            )
    }
}

struct RackBackground: View {
    var rackSquares: [RackSquare]
    @EnvironmentObject var rackSlots: SlotRow
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<NUM_RACK_TILES) { tileIndex in
                self.rackSquares[tileIndex]
            }
        }
    }
}

struct RackForeground: View {
    var tiles: [Tile]
    var shuffleState: [Tile]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<self.tiles.count) { tileIndex in
                ZStack {
                    self.shuffleState[tileIndex]
                    self.tiles[tileIndex]
                }
            }
        }
    }
}

struct BoardSquare: View {
    
    let size: Int
    let color: Color
    let row: Int
    let column: Int
    @EnvironmentObject var boardSlots: SlotGrid
    
    var body: some View {
        Rectangle()
            .fill(self.color)
            .border(Color.black)
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
}

struct BoardBackground: View {
    let boardSquares: [[BoardSquare]]
    @EnvironmentObject var boardSlots: SlotGrid
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<self.boardSquares.count) { row in
                HStack(spacing: 0) {
                    ForEach(0..<self.boardSquares[0].count) { column in
                        self.boardSquares[row][column]
                    }
                }
            }
        }.border(Color.black, width: 2)
    }
}

struct BoardForeground: View {
    let tiles: [[Tile]]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<NUM_BOARD_ROWS) { row in
                HStack(spacing: 0) {
                    ForEach(0..<NUM_BOARD_COLUMNS) { column in
                        self.tiles[row][column]
                    }
                }
            }
        }
    }
}

class SlotGrid: ObservableObject {
    @Published var grid: [[CGRect]]
    
    init(num_rows: Int, num_columns: Int) {
        self.grid = [[CGRect]](repeating: [CGRect](repeating: .zero, count: num_columns), count: num_rows)
    }
}

class SlotRow: ObservableObject {
    @Published var slots: [CGRect]
    
    init(num_slots: Int) {
        self.slots = [CGRect](repeating: .zero, count: num_slots)
    }
}




