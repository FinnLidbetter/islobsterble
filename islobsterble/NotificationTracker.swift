//
//  NotificationTracker.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2021-07-18.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import Foundation
import SwiftUI

class NotificationTracker: ObservableObject {
    @Published var deviceTokenString: String? = nil
    @Published var refreshGames = [String]()
    @Published var refreshGameView = false
    var fromBackground = false
    
    func setRefreshGameView(value: Bool) {
        DispatchQueue.main.async {
            self.refreshGameView = value
        }
    }
}
