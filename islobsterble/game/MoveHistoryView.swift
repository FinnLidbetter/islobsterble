//
//  MoveHistoryView.swift
//  islobsterble
//  View for showing the history of turns played.
//
//  Created by Finn Lidbetter on 2021-01-12.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import SwiftUI


struct MoveHistoryView: View {
    let gameId: String
    @EnvironmentObject var accessToken: ManagedAccessToken
    @Binding var loggedIn: Bool
    @Binding var inGame: Bool
    @State private var playerMoves: [PlayerMovesSerializer] = []
    @State private var selection: Set<Int> = []
    @State private var errorMessages = ErrorMessageQueue()
    
    var body: some View {
        ZStack {
            VStack {
                List {
                    Section(header: HStack(spacing: 8) {
                        ForEach(0..<playerMoves.count, id: \.self) { playerIndex in
                            Text("\(self.playerMoves[playerIndex].player.display_name)").frame(maxWidth: .infinity)
                        }
                    }) {
                        ForEach(0..<self.numMoveRows(), id: \.self) { moveRowIndex in
                            MoveRowView(isExpanded: self.selection.contains(moveRowIndex), moves: self.rowMoves(row: moveRowIndex)).onTapGesture {
                                self.selectDeselect(rowIndex: moveRowIndex)
                            }
                        }
                    }
                }.onAppear {
                    self.getMoveHistory()
                }
            }.frame(maxWidth: .infinity)
            ErrorView(errorMessages: self.errorMessages)
        }
    }
    
    func getMoveHistory() {
        self.accessToken.renewedRequest(successCompletion: self.getMoveHistoryRequest, errorCompletion: self.getMoveHistoryError)
    }
    
    private func getMoveHistoryRequest(token: Token) {
        guard let url = URL(string: ROOT_URL + "api/game/\(self.gameId)/move-history") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.addAuthorization(token: token)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    if let decodedPlayerMoves = try? decoder.decode([PlayerMovesSerializer].self, from: data) {
                        self.playerMoves = decodedPlayerMoves
                    } else {
                        self.errorMessages.offer(value: "Internal error. Failed to decode move history data.")
                    }
                } else {
                    self.errorMessages.offer(value: String(decoding: data, as: UTF8.self))
                }
            } else {
                self.errorMessages.offer(value: error?.localizedDescription ?? "Error")
            }
        }.resume()
    }
    
    private func getMoveHistoryError(error: RenewedRequestError) {
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
            self.errorMessages.offer(value: "Internal error decoding token refresh data in getting move history.")
        case .keyChainRetrieveError:
            self.inGame = false
            self.loggedIn = false
        case .urlError:
            self.errorMessages.offer(value: "Internal URL error in token refresh for getting move history.")
        }
    }
    
    
    private func numMoveRows() -> Int {
        if self.playerMoves.count == 0 {
            return 0
        }
        return self.playerMoves[0].moves.count
    }
    private func rowMoves(row: Int) -> [MoveSerializer?] {
        var moves: [MoveSerializer?] = []
        for playerMoves in self.playerMoves {
            if row < playerMoves.moves.count {
                moves.append(playerMoves.moves[row])
            } else {
                moves.append(nil)
            }
        }
        return moves
    }
    private func selectDeselect(rowIndex: Int) {
        if self.selection.contains(rowIndex) {
            self.selection.remove(rowIndex)
        } else {
            self.selection.insert(rowIndex)
        }
    }
}
struct MoveRowView: View {
    
    let isExpanded: Bool
    let moves: [MoveSerializer?]
    
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                ForEach(0..<self.moves.count, id: \.self) { playerIndex in
                    Text(self.primaryDisplayString(move: self.moves[playerIndex])).frame(maxWidth: .infinity)
                }
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            }
            if isExpanded {
                HStack(spacing: 8) {
                    ForEach(0..<self.moves.count, id: \.self) { playerIndex in
                        VStack {
                            ForEach(self.expandDisplayStrings(move: self.moves[playerIndex]), id: \.self) { secondaryWord in
                                Text(secondaryWord)
                            }
                        }.frame(maxWidth: .infinity)
                    }
                    Image(systemName: "chevron.down").opacity(0)
                }
            }
        }.frame(maxWidth: .infinity)
    }
    private func primaryDisplayString(move: MoveSerializer?) -> String {
        var text = ""
        if move == nil {
            return text
        }
        if move!.exchanged_tiles.count > 0 {
            text = "Exchange"
        } else if move!.primary_word != nil {
            text = "\(move!.primary_word!):\(move!.score)"
        } else {
            text = "Pass"
        }
        return text
    }
    private func expandDisplayStrings(move: MoveSerializer?) -> [String] {
        if move == nil {
            return []
        }
        if move!.primary_word != nil && move!.secondary_words != nil {
            return move!.secondary_words!.components(separatedBy: ",")
        } else if move!.exchanged_tiles.count > 0 {
            var exchangedLetters: [String] = []
            for tileCount in move!.exchanged_tiles {
                var tileCharacter = ""
                if tileCount.tile.is_blank {
                    tileCharacter = "_"
                } else {
                    tileCharacter = tileCount.tile.letter!
                }
                for _ in 0..<tileCount.count {
                    exchangedLetters.append(tileCharacter)
                }
            }
            return [exchangedLetters.joined(separator: ",")]
        }
        return []
    }
}
 

struct PlayerMovesSerializer: Codable {
    let player: HistoryPlayerSerializer
    let moves: [MoveSerializer]
    let turn_order: Int
}
struct HistoryPlayerSerializer: Codable {
    let id: Int
    let display_name: String
}
struct MoveSerializer: Codable {
    let primary_word: String?
    let secondary_words: String?
    let exchanged_tiles: [HistoryTileCountSerializer]
    let turn_number: Int
    let score: Int
}
struct HistoryTileCountSerializer: Codable {
    let tile: HistoryTileSerializer
    let count: Int
}
struct HistoryTileSerializer: Codable {
    let letter: String?
    let is_blank: Bool
    let value: Int
}
