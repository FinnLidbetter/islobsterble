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
                TextField("", text: $queryWord)
                    .background(
                        Rectangle().fill(Color.white).border(Color.black, width: 2))
                    .padding()
                Button(action: self.submitQueryWord) {
                    Text("Lookup Word")
                }
                Button(action: self.submitWordToDictionary) {
                    Text("Add to Dictionary")
                }
                // Rack
                // Board
            }
            .navigationBarTitle("Dictionary", displayMode: .inline)
        }
    }
    
    func submitQueryWord() {
        
    }
    func submitWordToDictionary() {
        
    }
}

struct DictionaryView_Previews: PreviewProvider {
    static var previews: some View {
        DictionaryView()
    }
}
