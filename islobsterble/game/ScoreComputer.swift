//
//  ScoreComputer.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2021-09-13.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import Foundation


class ScoreComputer {
    let boardLetters: [[Letter]]
    let locked: [[Bool]]
    let letterMultipliers: [[Int]]
    let wordMultipliers: [[Int]]
    let unlockedPositionedValues: [PositionedValue]
    
    init(boardLetters: [[Letter]], locked: [[Bool]], letterMultipliers: [[Int]], wordMultipliers: [[Int]]) {
        self.boardLetters = boardLetters
        self.locked = locked
        var positionedValues: [PositionedValue] = []
        for row in 0..<boardLetters.count {
            for column in 0..<boardLetters[row].count {
                if boardLetters[row][column] != INVISIBLE_LETTER && !locked[row][column] {
                    positionedValues.append(PositionedValue(row: row, column: column, value: self.boardLetters[row][column].value!))
                }
            }
        }
        positionedValues.sort {
            if $0.row == $1.row {
                return $0.column < $1.column
            }
            return $0.row < $1.row
        }
        self.unlockedPositionedValues = positionedValues
        self.letterMultipliers = letterMultipliers
        self.wordMultipliers = wordMultipliers
    }
    
    func computeScore() -> Int? {
        if unlockedPositionedValues.count == 0 {
            return 0
        }
        guard let axis = self.getAxis() else {
            return nil
        }
        if !self.isContiguous(axis: axis) {
            return nil
        }
        if self.isSingleLetterInCenter() {
            let centerRow = self.unlockedPositionedValues[0].row
            let centerColumn = self.unlockedPositionedValues[0].column
            return self.unlockedPositionedValues[0].value * self.letterMultipliers[centerRow][centerColumn] * self.wordMultipliers[centerRow][centerColumn]
        }
        var sum = 0
        let oppositeAxis = axis == Axis.horizontal ? Axis.vertical : Axis.horizontal
        for positionedValue in self.unlockedPositionedValues {
            sum += self.scoreAxis(axis: oppositeAxis, baseRow: positionedValue.row, baseColumn: positionedValue.column)
        }
        sum += self.scoreAxis(
            axis: axis, baseRow: self.unlockedPositionedValues[0].row, baseColumn: self.unlockedPositionedValues[0].column)
        if self.unlockedPositionedValues.count == NUM_RACK_TILES {
            sum += BINGO_BONUS
        }
        if sum == 0 && self.unlockedPositionedValues.count == 1 {
            // Hack to show a count for a single letter placed not next to another letter.
            // This could also be triggered if a blank is played next to another blank
            // but that is ok.
            sum += self.unlockedPositionedValues[0].value * self.letterMultipliers[self.unlockedPositionedValues[0].row][self.unlockedPositionedValues[0].column] * self.wordMultipliers[self.unlockedPositionedValues[0].row][self.unlockedPositionedValues[0].column]
        }
        return sum
    }
    
    private func getAxis() -> Axis? {
        var rows = Set<Int>()
        var columns = Set<Int>()
        for positionedValue in self.unlockedPositionedValues {
            rows.insert(positionedValue.row)
            columns.insert(positionedValue.column)
        }
        if rows.count > 1 && columns.count > 1 {
            return nil
        }
        if rows.count == 1 {
            return Axis.horizontal
        }
        return Axis.vertical
    }
    private func isContiguous(axis: Axis) -> Bool {
        let dr = axis == Axis.horizontal ? 0 : 1
        let dc = axis == Axis.horizontal ? 1 : 0
        let nUnlocked = self.unlockedPositionedValues.count
        var row = self.unlockedPositionedValues[0].row
        var column = self.unlockedPositionedValues[0].column
        let rowMax = self.unlockedPositionedValues[nUnlocked - 1].row
        let columnMax = self.unlockedPositionedValues[nUnlocked - 1].column
        while row <= rowMax && column <= columnMax {
            if self.boardLetters[row][column] == INVISIBLE_LETTER {
                return false
            }
            row += dr
            column += dc
        }
        return true
    }
    
    private func isSingleLetterInCenter() -> Bool {
        if self.unlockedPositionedValues.count != 1 {
            return false
        }
        let row = self.unlockedPositionedValues[0].row
        let column = self.unlockedPositionedValues[0].column
        let numRows = self.boardLetters.count
        let numColumns = self.boardLetters[0].count
        return row == (numRows - 1) / 2 && column == (numColumns - 1) / 2
    }
    
    private func verticalMin(startRow: Int, startColumn: Int) -> Int {
        var row = startRow
        while row > 0 && self.boardLetters[row - 1][startColumn] != INVISIBLE_LETTER {
            row -= 1
        }
        return row
    }
    private func verticalMax(startRow: Int, startColumn: Int) -> Int {
        var row = startRow
        while row < self.boardLetters.count - 1 && self.boardLetters[row + 1][startColumn] != INVISIBLE_LETTER {
            row += 1
        }
        return row
    }
    private func horizontalMin(startRow: Int, startColumn: Int) -> Int {
        var column = startColumn
        while column > 0 && self.boardLetters[startRow][column - 1] != INVISIBLE_LETTER {
            column -= 1
        }
        return column
    }
    private func horizontalMax(startRow: Int, startColumn: Int) -> Int {
        var column = startColumn
        while column < self.boardLetters[startRow].count - 1 && self.boardLetters[startRow][column + 1] != INVISIBLE_LETTER {
            column += 1
        }
        return column
    }
    private func scoreAxis(axis: Axis, baseRow: Int, baseColumn: Int) -> Int {
        let dr = axis == Axis.horizontal ? 0 : 1
        let dc = axis == Axis.horizontal ? 1 : 0
        var row = -1
        var rowMax = -1
        var column = -1
        var columnMax = -1
        if axis == Axis.horizontal {
            row = baseRow
            rowMax = baseRow
            column = self.horizontalMin(startRow: baseRow, startColumn: baseColumn)
            columnMax = self.horizontalMax(startRow: baseRow, startColumn: baseColumn)
        } else {
            row = self.verticalMin(startRow: baseRow, startColumn: baseColumn)
            rowMax = self.verticalMax(startRow: baseRow, startColumn: baseColumn)
            column = baseColumn
            columnMax = baseColumn
        }
        if row == rowMax && column == columnMax {
            return 0
        }
        var wordMultiplier = 1
        var wordSum = 0
        while row <= rowMax && column <= columnMax {
            var letterScore = self.boardLetters[row][column].value!
            if !self.locked[row][column] {
                wordMultiplier *= self.wordMultipliers[row][column]
                letterScore *= self.letterMultipliers[row][column]
            }
            wordSum += letterScore
            row += dr
            column += dc
        }
        wordSum *= wordMultiplier
        return wordSum
    }
}
enum Axis {
    case horizontal, vertical
}
struct PositionedValue {
    let row: Int
    let column: Int
    let value: Int
}
