//
//  DictionaryView.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2020-12-26.
//  Copyright © 2020 Finn Lidbetter. All rights reserved.
//

import SwiftUI

struct DictionaryView: View {
    @State private var queryWord: String = ""
    
    var body: some View {
        NavigationView() {
            VStack {
                TextField("Lookup", text: $queryWord)
                Button(action: self.submitQueryWord) {
                    Text("Submit Word")
                }
                // Rack
                // Board
            }
            .navigationBarTitle("Dictionary", displayMode: .inline)
        }
    }
    
    func submitQueryWord() {
        
    }
}

struct DictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryView()
    }
}
