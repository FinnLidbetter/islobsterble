//
//  PlaySpace.swift
//  islobsterble
//  View for a game board and tile rack and their interactions.
//
//  Created by Finn Lidbetter on 2020-12-27.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

let SCREEN_SIZE: CGRect = UIScreen.main.bounds

let BLANK = Character("-")
let INVISIBLE = Character(" ")
let INVISIBLE_LETTER = Letter(letter: INVISIBLE, is_blank: false, value: nil)
let NUM_RACK_TILES = 7
let DEFAULT_ROWS = 15
let DEFAULT_COLUMNS = 15
let BINGO_BONUS = 50

enum FrontTaker {
    /*
     * States for tracking whether board tiles or rack tiles should appear at the front.
     *
     * This allows tiles dragged from the board to appear over all rack tiles
     * and vice versa.
     */
    case unknown
    case board
    case rack
}

struct PlaySpace: View {
    let width: Int = Int(SCREEN_SIZE.width)
    @Binding var gameId: String?
    @Binding var loggedIn: Bool
    @Binding var inGame: Bool
    
    @EnvironmentObject var notificationTracker: NotificationTracker
    
    @EnvironmentObject var accessToken: ManagedAccessToken
    @State private var numBoardRows = 15
    @State private var numBoardColumns = 15
    @State private var playerScores = [PlayerScore]()
    @State private var turnNumber = 0
    @State private var boardLetters = [[Letter]](repeating: [Letter](repeating: INVISIBLE_LETTER, count: DEFAULT_COLUMNS), count: DEFAULT_ROWS)
    @State private var locked = [[Bool]](repeating: [Bool](repeating: false, count: DEFAULT_COLUMNS), count: DEFAULT_ROWS)
    @State private var letterMultipliers = [[Int]](repeating: [Int](repeating: 1, count: DEFAULT_COLUMNS), count: DEFAULT_ROWS)
    @State private var wordMultipliers = [[Int]](repeating: [Int](repeating: 1, count: DEFAULT_COLUMNS), count: DEFAULT_ROWS)
    @State private var numTilesRemaining = 86
    @State private var gameOver = false
    
    @State private var rackTilesOnBoardCount: Int = 0
    @State private var rackLetters = [Letter](repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
    @State private var rackShuffleState: [Letter] = [Letter](repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
    
    @State private var prevMove: PrevMoveSerializer?
    
    // Variables for managing Z-positioning of dragged tiles.
    @State private var frontTaker: FrontTaker = FrontTaker.unknown
    
    // Variables for the blank picker.
    @State private var showBlankPicker = false
    @State private var prevBlankRow: Int? = nil
    @State private var prevBlankColumn: Int? = nil
    
    // Variables for the exchange picker.
    @State private var showExchangePicker = false
    @State private var exchangeChosen = [Bool](repeating: false, count: NUM_RACK_TILES)
    
    // Variables for the pass confirmation dialog.
    @State private var showPassConfirmer = false
    
    // Error message
    @StateObject private var errorMessages = ErrorMessageQueue()
    
    // Variable for tracking refreshes after the bag is empty.
    @State private var emptyBagRefreshCount = 0
    
    // Environment variables.
    @ObservedObject var boardSlots = SlotGrid(num_rows: DEFAULT_ROWS, num_columns: DEFAULT_COLUMNS)
    @ObservedObject var rackSlots = SlotRow(num_slots: NUM_RACK_TILES)
    
    var body: some View {
        ZStack {
            VStack {
                ScorePanel(playerScores: self.playerScores, turnNumber: self.turnNumber, prevMove: self.prevMove, boardScore:
                            ScoreComputer(boardLetters: self.boardLetters, locked: self.locked, letterMultipliers: self.letterMultipliers, wordMultipliers: self.wordMultipliers).computeScore())
                Spacer()
                ZStack {
                    VStack(spacing: 20) {
                        BoardBackground(boardSquares: setupBoardSquares()).environmentObject(self.boardSlots)
                        RackBackground(rackSquares: setupRackSquares()).environmentObject(self.rackSlots)
                    }
                    VStack(spacing: 20) {
                        BoardForeground(tiles: setupBoardTiles(), locked: self.locked, showingPicker: self.showBlankPicker || self.showExchangePicker || self.showPassConfirmer).zIndex(self.frontTaker == FrontTaker.board ? 1 : 0)
                        RackForeground(tiles: setupRackTiles(), shuffleState: setupShuffleState(), showingPicker: self.showBlankPicker || self.showExchangePicker || self.showPassConfirmer).zIndex(self.frontTaker == FrontTaker.rack ? 1 : 0)
                    }
                    BlankPicker(isPresented: $showBlankPicker, onSelection: self.setBlank)
                    ExchangePicker(isPresented: $showExchangePicker, rackLetters: self.rackLetters, chosen: $exchangeChosen, onSelectTile: self.chooseTileForExchange, onExchange: self.confirmExchange)
                    PassConfirmer(isPresented: $showPassConfirmer, onPassConfirm: self.confirmPass)
                }
                ActionPanel(
                    loggedIn: self.$loggedIn,
                    inGame: self.$loggedIn,
                    gameId: self.gameId!,
                    tilesRemaining: self.numTilesRemaining,
                    rackTilesOnBoard: self.rackTilesOnBoardCount > 0,
                    showingPicker: self.showBlankPicker || self.showExchangePicker || self.showPassConfirmer,
                    onShuffle: self.shuffleTiles,
                    onRecall: self.recallTiles,
                    onPass: self.selectPass,
                    onPlay: self.confirmPlay,
                    onExchange: self.selectExchange
                ).padding(.bottom, 10)
            }
            ErrorView(errorMessages: self.errorMessages)
        }
        .navigationBarTitle("Game", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backToMenu, trailing: Button(action: {
            self.getGameState()
        }) {
            Image(systemName: "arrow.clockwise").font(.system(size: 25.0))
        })
        .onAppear() {
            notificationTracker.setRefreshGameView(value: false)
            self.getGameState()
        }
        .onChange(of: notificationTracker.refreshGames) { gamesToRefresh in
            if notificationTracker.fromBackground {
                let notifiedGameId = gamesToRefresh.first
                if notifiedGameId != nil {
                    self.gameId = notifiedGameId!
                }
                notificationTracker.fromBackground = false
            }
            if gamesToRefresh.contains(self.gameId!) {
                if let gameIndex = notificationTracker.refreshGames.firstIndex(of: self.gameId!) {
                    notificationTracker.refreshGames.remove(at: gameIndex)
                }
                self.getGameState()
            }
        }
        .onChange(of: notificationTracker.refreshGameView) { refreshGameView in
            if refreshGameView {
                self.getGameState()
                notificationTracker.setRefreshGameView(value: false)
            }
        }
    }
    
    var backToMenu: some View {
        Button(action: { self.inGame = false }) {
            HStack {
                Image(systemName: "chevron.left").aspectRatio(contentMode: .fit)
                Text("Menu")
            }
        }
    }
    
    private func chooseTileForExchange(index: Int) {
        self.exchangeChosen[index] = !self.exchangeChosen[index]
    }
    
    func confirmExchange() {
        self.accessToken.renewedRequest(successCompletion: self.confirmExchangeRequest, errorCompletion: self.playTurnRenewError)
    }
    
    func confirmPass() {
        self.accessToken.renewedRequest(successCompletion: self.confirmPassRequest, errorCompletion: self.playTurnRenewError)
    }
    
    func confirmPlay() {
        self.accessToken.renewedRequest(successCompletion: self.confirmPlayRequest, errorCompletion: self.playTurnRenewError)
    }
    
    private func confirmExchangeRequest(token: Token) {
        var playedTiles = [TurnPlayedTileSerializer]()
        for rackIndex in 0..<NUM_RACK_TILES {
            if self.exchangeChosen[rackIndex] {
                let currLetter = self.rackLetters[rackIndex]
                playedTiles.append(
                    TurnPlayedTileSerializer(
                        letter: currLetter.is_blank ? nil : String(currLetter.letter),
                        is_blank: currLetter.is_blank,
                        value: currLetter.value ?? 0,
                        row: nil,
                        column: nil,
                        is_exchange: true
                    )
                )
            }
        }
        let turn = TurnSerializer(played_tiles: playedTiles)
        self.showExchangePicker = false
        for rackIndex in 0..<NUM_RACK_TILES {
            self.exchangeChosen[rackIndex] = false
        }
        self.submitTurn(turn: turn, token: token)
    }
    
    private func playTurnRenewError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.inGame = false
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal decode error.")
        case .keyChainRetrieveError:
            self.inGame = false
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error.")
        }
    }
    
    private func confirmPassRequest(token: Token) {
        let playedTiles = [TurnPlayedTileSerializer]()
        let turn = TurnSerializer(played_tiles: playedTiles)
        self.submitTurn(turn: turn, token: token)
    }
    
    private func confirmPlayRequest(token: Token) {
        var playedTiles = [TurnPlayedTileSerializer]()
        for row in 0..<self.numBoardRows {
            for column in 0..<self.numBoardColumns {
                if !self.locked[row][column] && self.boardLetters[row][column] != INVISIBLE_LETTER {
                    let currLetter = self.boardLetters[row][column]
                    playedTiles.append(
                        TurnPlayedTileSerializer(
                            letter: String(currLetter.letter),
                            is_blank: currLetter.is_blank,
                            value: currLetter.value ?? 0,
                            row: row,
                            column: column,
                            is_exchange: false))
                }
            }
        }
        let turn = TurnSerializer(played_tiles: playedTiles)
        self.submitTurn(turn: turn, token: token)
    }
    
    private func submitTurn(turn: TurnSerializer, token: Token) {
        guard let encodedTurnData = try? JSONEncoder().encode(turn.played_tiles) else {
            self.errorMessages.offer(value: "Internal error encoding turn data.")
            return
        }
        guard let url = URL(string: ROOT_URL + "api/game/\(self.gameId!)") else {
            self.errorMessages.offer(value: "Internal error creating submit turn URL.")
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addAuthorization(token: token)
        request.httpMethod = "POST"
        request.httpBody = encodedTurnData
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    self.errorMessages.clear()
                } else {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                    print(self.errorMessages.peek()!)
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
            self.getGameState()
        }.resume()
    }
    
    private func selectExchange() {
        self.recallTiles()
        self.showExchangePicker = true
    }
    
    private func selectPass() {
        self.showPassConfirmer = true
    }
    
    private func shuffleTiles() {
        let order = UtilityFuncs.permutation(size: NUM_RACK_TILES)
        var copy: [Letter] = []
        for index in 0..<NUM_RACK_TILES {
            copy.append(self.rackLetters[index])
        }
        for index in 0..<NUM_RACK_TILES {
            self.rackLetters[index] = copy[order[index]]
        }
    }
    
    private func recallTiles() {
        var rackIndex = nextEmptyRackIndex(start: 0)
        if rackIndex == nil {
            self.rackTilesOnBoardCount = 0
            return
        }
        for row in 0..<self.numBoardRows {
            for column in 0..<self.numBoardColumns {
                if !locked[row][column] && self.boardLetters[row][column] != INVISIBLE_LETTER {
                    var modifiedLetter = self.boardLetters[row][column]
                    if modifiedLetter.is_blank {
                        modifiedLetter = Letter(letter: BLANK, is_blank: true, value: modifiedLetter.value)
                    }
                    self.rackLetters[rackIndex!] = modifiedLetter
                    self.boardLetters[row][column] = INVISIBLE_LETTER
                    rackIndex = nextEmptyRackIndex(start: rackIndex!)
                    if rackIndex == nil {
                        self.rackTilesOnBoardCount = 0
                        return
                    }
                }
            }
        }
        self.rackTilesOnBoardCount = 0
    }
    private func nextEmptyRackIndex(start: Int) -> Int? {
        var rackIndex = start
        while rackIndex < NUM_RACK_TILES && self.rackLetters[rackIndex] != INVISIBLE_LETTER {
            rackIndex += 1
        }
        if rackIndex >= NUM_RACK_TILES {
            return nil
        }
        return rackIndex
    }
    
    
    private func setBlank(choice: Character) {
        self.showBlankPicker = false
        let prevLetter = self.boardLetters[prevBlankRow!][prevBlankColumn!]
        assert(prevLetter.is_blank)
        assert(prevLetter.letter == BLANK)
        self.boardLetters[prevBlankRow!][prevBlankColumn!] = Letter(letter: choice, is_blank: true, value: prevLetter.value)
        self.prevBlankRow = nil
        self.prevBlankColumn = nil
    }
    
    private func nearestRackEmpty(newIndex: Int, originalIndex: Int?) -> Int {
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
    
    private func nearestBoardEmpty(targetRow: Int, targetColumn: Int) -> (Int, Int) {
        var vis = [[Bool]](repeating: [Bool](repeating: false, count: self.numBoardColumns), count: self.numBoardRows)
        let rowQueue = IntQueue(maxSize: self.numBoardRows * self.numBoardColumns)
        let columnQueue = IntQueue(maxSize: self.numBoardRows * self.numBoardColumns)
        
        rowQueue.offer(targetRow)
        columnQueue.offer(targetColumn)
        let dr = [1, 0, -1, 0]
        let dc = [0, 1, 0, -1]
        
        vis[targetRow][targetColumn] = true
        while rowQueue.getSize() > 0 {
            let currRow = rowQueue.poll()!
            let currColumn = columnQueue.poll()!
            if self.boardLetters[currRow][currColumn] == INVISIBLE_LETTER {
                return (currRow, currColumn)
            }
            for index in 0..<4 {
                let nextRow = currRow + dr[index]
                let nextColumn = currColumn + dc[index]
                if nextRow < 0 || nextRow >= self.numBoardRows || nextColumn < 0 || nextColumn >= self.numBoardColumns {
                    continue
                }
                if !vis[nextRow][nextColumn] {
                    vis[nextRow][nextColumn] = true
                    rowQueue.offer(nextRow)
                    columnQueue.offer(nextColumn)
                }
            }
        }
        return (-1, -1)
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
        let nearestEmptyIndex = nearestRackEmpty(newIndex: newIndex, originalIndex: originalIndex)
        
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
        for row in 0..<self.numBoardRows {
            for column in 0..<self.numBoardColumns {
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
            let endPair = nearestBoardEmpty(targetRow: endPosition.boardRow!, targetColumn: endPosition.boardColumn!)
            let endRow = endPair.0
            let endColumn = endPair.1
            if startPosition.rackIndex != nil {
                self.rackLetters[startPosition.rackIndex!] = INVISIBLE_LETTER
                if letter.is_blank {
                    self.showBlankPicker.toggle()
                    self.prevBlankRow = endRow
                    self.prevBlankColumn = endColumn
                }
                self.rackTilesOnBoardCount += 1
            } else {
                self.boardLetters[startPosition.boardRow!][startPosition.boardColumn!] = INVISIBLE_LETTER
            }
            self.boardLetters[endRow][endColumn] = letter
        } else if endPosition.rackIndex != nil {
            if startPosition.rackIndex != nil {
                self.rackLetters[startPosition.rackIndex!] = INVISIBLE_LETTER
                self.rackLetters[endPosition.rackIndex!] = letter
            }
            if startPosition.boardRow != nil && startPosition.boardColumn != nil {
                self.boardLetters[startPosition.boardRow!][startPosition.boardColumn!] = INVISIBLE_LETTER
                var modifiedLetter = letter
                if letter.is_blank {
                    modifiedLetter = Letter(letter: BLANK, is_blank: true, value: letter.value)
                }
                self.rackLetters[endPosition.rackIndex!] = modifiedLetter
                self.rackTilesOnBoardCount -= 1
            }
        } else {
            if startPosition.rackIndex != nil && self.rackShuffleState[startPosition.rackIndex!] != INVISIBLE_LETTER {
                // Make sure that we are not losing the dragged tile.
                for index in 0..<NUM_RACK_TILES {
                    if self.rackLetters[index] == INVISIBLE_LETTER {
                        self.rackLetters[index] = letter
                        break
                    }
                }
            }
        }
        for index in 0..<NUM_RACK_TILES {
            if self.rackShuffleState[index] != INVISIBLE_LETTER {
                self.rackLetters[index] = self.rackShuffleState[index]
            }
        }
        self.rackShuffleState = [Letter](repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
        if !self.gameOver {
            self.persistRackState()
        }
    }
    
    private func getBoardSquareSize() -> Int {
        return (self.width - 10) / self.numBoardColumns
    }
    private func getRackSquareSize() -> Int {
        return (self.width - 10) / NUM_RACK_TILES
    }
    
    private func setupBoardTiles() -> [[Tile]] {
        var boardTiles: [[Tile]] = []
        let boardSquareSize = self.getBoardSquareSize()
        for row in 0..<self.numBoardRows {
            var boardRow: [Tile] = []
            for column in 0..<self.numBoardColumns {
                boardRow.append(Tile(
                    size: boardSquareSize,
                    face: boardLetters[row][column],
                    position: Position(boardRow: row, boardColumn: column, rackIndex: nil),
                    allowDrag: true,
                    onChanged: self.tileMoved,
                    onEnded: self.tileDropped
                ))
            }
            boardTiles.append(boardRow)
        }
        return boardTiles
    }
    
    private func setupBoardSquares() -> [[BoardSquare]] {
        var boardSquares: [[BoardSquare]] = []
        let boardSquareSize = self.getBoardSquareSize()
        for row in 0..<self.numBoardRows {
            var boardSquareRow: [BoardSquare] = []
            for column in 0..<self.numBoardColumns {
                boardSquareRow.append(BoardSquare(size: boardSquareSize, letterMultiplier: self.letterMultipliers[row][column], wordMultiplier: self.wordMultipliers[row][column], row: row, column: column))
            }
            boardSquares.append(boardSquareRow)
        }
        return boardSquares
    }
    
    private func setupRackTiles() -> [Tile] {
        var rackTiles: [Tile] = []
        let rackTileSize = self.getRackSquareSize()
        for index in 0..<NUM_RACK_TILES {
            rackTiles.append(Tile(
                    size: rackTileSize,
                    face: self.rackLetters[index],
                    position: Position(boardRow: nil, boardColumn: nil, rackIndex: index),
                    allowDrag: true,
                    onChanged: self.tileMoved,
                    onEnded: self.tileDropped))
        }
        return rackTiles
    }
    
    private func setupShuffleState() -> [Tile] {
        var shuffleTiles: [Tile] = []
        let rackTileSize = self.getRackSquareSize()
        for index in 0..<NUM_RACK_TILES {
            shuffleTiles.append(Tile(
                size: rackTileSize,
                face: self.rackShuffleState[index],
                position: Position(boardRow: nil, boardColumn: nil, rackIndex: index),
                allowDrag: true,
                onChanged: self.tileMoved,
                onEnded: self.tileDropped))
        }
        return shuffleTiles
    }
    
    private func setupRackSquares() -> [RackSquare] {
        var rackSquares: [RackSquare] = []
        let rackSquareSize = self.getRackSquareSize()
        for index in 0..<NUM_RACK_TILES {
            rackSquares.append(RackSquare(size: rackSquareSize, color: Color.clear, index: index))
        }
        return rackSquares
    }
    
    func getGameState() {
        self.accessToken.renewedRequest(successCompletion: self.getGameStateRequest, errorCompletion: self.getGameStateError)
    }
    
    private func getGameStateRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/game/\(self.gameId!)") else {
            self.errorMessages.offer(value: "Internal error creating get game state URL.")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        request.addValue("v3", forHTTPHeaderField: "Accept-version")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    if let gameState = try? JSONDecoder().decode(GameSerializer.self, from: data) {
                        self.clearBoard(rows: gameState.board_layout.rows, columns: gameState.board_layout.columns)
                        for modifier in gameState.board_layout.modifiers {
                            self.wordMultipliers[modifier.row][modifier.column] = modifier.modifier.word_multiplier
                            self.letterMultipliers[modifier.row][modifier.column] = modifier.modifier.letter_multiplier
                        }
                        if gameState.prev_move != nil {
                            withAnimation {
                                for playedTileIndex in 0..<gameState.prev_move!.played_tiles.count {
                                    let playedTile = gameState.prev_move!.played_tiles[playedTileIndex]
                                    self.boardLetters[playedTile.row][playedTile.column] = Letter(letter: Character(playedTile.tile.letter!), is_blank: playedTile.tile.is_blank, value: playedTile.tile.value)
                                    self.locked[playedTile.row][playedTile.column] = true
                                }
                            }
                        }
                        for playedTileIndex in 0..<gameState.board_state.count {
                            let playedTile = gameState.board_state[playedTileIndex]
                            self.boardLetters[playedTile.row][playedTile.column] = Letter(letter: Character(playedTile.tile.letter!), is_blank: playedTile.tile.is_blank, value: playedTile.tile.value)
                            self.locked[playedTile.row][playedTile.column] = true
                        }

                        self.clearRack()
                        var rackIndex = 0
                        for tileCountIndex in 0..<gameState.rack.count {
                            let tileCount = gameState.rack[tileCountIndex]
                            let tile = tileCount.tile
                            for _ in 0..<tileCount.count {
                                self.rackLetters[rackIndex] = Letter(letter: tile.is_blank ? BLANK : Character(tile.letter!), is_blank: tile.is_blank, value: tile.value)
                                rackIndex += 1
                            }
                        }
                        let savedRackState = self.retrieveRackState()
                        if self.equalTileCounts(letters_1: self.rackLetters, letters_2: savedRackState) {
                            self.rackLetters = savedRackState
                        }
                        self.playerScores = []
                        for gamePlayerIndex in 0..<gameState.game_players.count {
                            self.playerScores.append(
                                PlayerScore(playerId: gameState.game_players[gamePlayerIndex].player.id,
                                            playerName: gameState.game_players[gamePlayerIndex].player.display_name,
                                            score: gameState.game_players[gamePlayerIndex].score,
                                            turnOrder: gameState.game_players[gamePlayerIndex].turn_order))
                        }
                        self.playerScores.sort {
                            return $0.turnOrder < $1.turnOrder
                        }
                        self.turnNumber = gameState.turn_number
                        self.prevMove = gameState.prev_move
                        self.numTilesRemaining = gameState.num_tiles_remaining
                        if gameState.num_tiles_remaining == 0 || gameState.completed != nil {
                            var message = ""
                            var highestScore = -987654321
                            var highestScorers: [String] = []
                            if gameState.completed != nil {
                                self.gameOver = true
                            }
                            for gamePlayerIndex in 0..<gameState.game_players.count {
                                let gamePlayer = gameState.game_players[gamePlayerIndex]
                                if gamePlayer.num_tiles_remaining == 0 {
                                    self.gameOver = true
                                }
                                if self.emptyBagRefreshCount % SHOW_TILES_REMAINING_INTERVAL == 0 {
                                    if gamePlayer.player.id != gameState.fetcher_player_id {
                                        message += "\(gamePlayer.player.display_name) has \(gamePlayer.num_tiles_remaining) tile\(gamePlayer.num_tiles_remaining == 1 ? "" : "s") left. "
                                    }
                                }
                                if gamePlayer.score > highestScore {
                                    highestScore = gamePlayer.score
                                    highestScorers = [gamePlayer.player.display_name]
                                } else if gamePlayer.score == highestScore {
                                    highestScorers.append(gamePlayer.player.display_name)
                                }
                            }
                            if self.gameOver {
                                self.clearPersistedRackState()
                                if highestScorers.count == 1 {
                                    message = "Game over. \(highestScorers[0]) has won!"
                                } else {
                                    message = "Game over. It was a draw!"
                                }
                            }
                            self.emptyBagRefreshCount += 1
                            if message != "" {
                                self.errorMessages.offer(value: message)
                            }
                        }
                    }
                }
            } else {
                self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            }
        }.resume()
    }
    
    private func getGameStateError(error: RenewedRequestError) {
        switch error {
        case let .renewAccessError(response):
            if response.statusCode == 401 {
                self.inGame = false
                self.loggedIn = false
            }
        case let .urlSessionError(sessionError):
            self.errorMessages.offer(value: CONNECTION_ERROR_STR)
            print(sessionError)
        case .decodeError:
            self.errorMessages.offer(value: "Internal error decoding token refresh data in getting game state.")
        case .keyChainRetrieveError:
            self.inGame = false
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for getting game state.")
        }
    }
    
    private func clearBoard(rows: Int, columns: Int) {
        self.boardLetters = Array(repeating: Array(repeating: INVISIBLE_LETTER, count: columns), count: rows)
        self.locked = Array(repeating: Array(repeating: false, count: columns), count: rows)
        self.wordMultipliers = Array(repeating: Array(repeating: 1, count: columns), count: rows)
        self.letterMultipliers = Array(repeating: Array(repeating: 1, count: columns), count: rows)
        self.rackTilesOnBoardCount = 0
    }
    
    private func clearRack() {
        self.rackLetters = Array(repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
        self.rackShuffleState = Array(repeating: INVISIBLE_LETTER, count: NUM_RACK_TILES)
    }
    
    private func persistRackState() {
        if self.rackTilesOnBoardCount == 0 {
            if let encoded = try? JSONEncoder().encode(self.rackLetters) {
                let defaults = UserDefaults.standard
                defaults.set(encoded, forKey: "slobsterble:\(self.gameId!):rack")
            }
        }
    }
    private func retrieveRackState() -> [Letter] {
        if let savedRackState = UserDefaults.standard.object(forKey: "slobsterble:\(self.gameId!):rack") as? Data, let loadedRackState = try? JSONDecoder().decode([Letter].self, from: savedRackState) {
            return loadedRackState
        }
        return []
    }
    private func clearPersistedRackState() {
        UserDefaults.standard.removeObject(forKey: "slobsterble:\(self.gameId!):rack")
    }
    private func countLetters(letters: [Letter]) -> [Letter: Int] {
        var counts: [Letter: Int] = [:]
        for letter in letters {
            if counts.keys.contains(letter) {
                counts[letter] = counts[letter]! + 1
            } else {
                counts[letter] = 0
            }
        }
        return counts
    }
    private func equalTileCounts(letters_1: [Letter], letters_2: [Letter]) -> Bool {
        let counts_1 = self.countLetters(letters: letters_1)
        let counts_2 = self.countLetters(letters: letters_2)
        for letter in counts_1.keys {
            if counts_1[letter] != counts_2[letter] {
                return false
            }
        }
        for letter in counts_2.keys {
            if counts_1[letter] != counts_2[letter] {
                return false
            }
        }
        return true
    }
}

struct TurnSerializer: Codable {
    let played_tiles: [TurnPlayedTileSerializer]
}
struct TurnPlayedTileSerializer: Codable {
    let letter: String?
    let is_blank: Bool
    let value: Int
    let row: Int?
    let column: Int?
    let is_exchange: Bool
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(letter, forKey: .letter)
        try container.encode(is_blank, forKey: .is_blank)
        try container.encode(value, forKey: .value)
        try container.encode(row, forKey: .row)
        try container.encode(column, forKey: .column)
        try container.encode(is_exchange, forKey: .is_exchange)
    }
}

struct GameSerializer: Codable {
    let board_state: [PlayedTileSerializer]
    let game_players: [GamePlayerSerializer]
    let board_layout: BoardLayoutSerializer
    let turn_number: Int
    let whose_turn_name: String
    let num_tiles_remaining: Int
    let rack: [TileCountSerializer]
    let prev_move: PrevMoveSerializer?
    let fetcher_player_id: Int
    let completed: Date?
}
struct PlayedTileSerializer: Codable {
    let tile: TileSerializer
    let row: Int
    let column: Int
}
struct TileSerializer: Codable {
    let letter: String?
    let is_blank: Bool
    let value: Int
}
struct TileCountSerializer: Codable {
    let tile: TileSerializer
    let count: Int
}
struct GamePlayerSerializer: Codable {
    let score: Int
    let turn_order: Int
    let player: PlayerSerializer
    let num_tiles_remaining: Int
}
struct PlayerSerializer: Codable {
    let display_name: String
    let id: Int
}
struct BoardLayoutSerializer: Codable {
    let rows: Int
    let columns: Int
    let modifiers: [PositionedModifierSerializer]
}
struct PositionedModifierSerializer: Codable {
    let row: Int
    let column: Int
    let modifier: ModifierSerializer
}
struct ModifierSerializer: Codable {
    let word_multiplier: Int
    let letter_multiplier: Int
}
struct PrevMoveSerializer: Codable {
    let word: String?
    let score: Int
    let player_id: Int
    let display_name: String
    let exchanged_count: Int
    let played_tiles: [PlayedTileSerializer]
}
