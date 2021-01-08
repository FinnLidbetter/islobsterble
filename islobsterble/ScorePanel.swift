//
//  ScorePanel.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct ScorePanel: View {
    let scores: [String: Int]
    var names: [String]
    var values: [Int]
    
    init(scores: [String: Int]) {
        self.scores = scores
        self.names = []
        self.values = []
        for (name, value) in scores {
            names.append(name)
            values.append(value)
        }
    }
    
    var body: some View {
        HStack {
            Text(self.names.count > 0 ? "\(self.names[0]): \(self.values[0])" : "")
            ForEach(1..<self.names.count, id: \.self) { index in
                Spacer()
                Text("\(self.names[index]): \(self.values[index])")
            }
        }.padding()
    }
}
