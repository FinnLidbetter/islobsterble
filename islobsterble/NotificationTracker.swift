//
//  NotificationTracker.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2021-07-18.
//  Copyright © 2021 Finn Lidbetter. All rights reserved.
//

import Foundation

class NotificationTracker: ObservableObject {
    @Published var deviceTokenString: String? = nil
    @Published var refreshGames: Set<String> = []
}
