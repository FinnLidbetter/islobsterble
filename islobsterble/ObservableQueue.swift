//
//  QueueNode.swift
//  islobsterble
//
//  Created by Finn Lidbetter on 2022-08-05.
//  Copyright © 2022 Finn Lidbetter. All rights reserved.
//

import Foundation

class ObservableQueue<T>: ObservableObject {
    
    var head: QueueNode<T>?
    var tail: QueueNode<T>?
    @Published var count = 0
    
    func offer(value: T) {
        let node = QueueNode<T>(value: value)
        if self.tail == nil {
            self.head = node
            self.tail = node
        } else {
            self.tail!.insertAfter(newQueueNode: node)
            self.tail = node
        }
        DispatchQueue.main.async {
            self.count += 1
        }
    }
    
    func poll() -> T? {
        if self.head == nil {
            return nil
        }
        let value = self.head!.value
        if self.head!.next == nil {
            self.head = nil
            self.tail = nil
        } else {
            self.head = self.head!.next
            self.head!.prev = nil
        }
        DispatchQueue.main.async {
            self.count -= 1
        }
        return value
    }
    func swallowedPoll() {
        let _ = self.poll()
    }
    
    func peek() -> T? {
        if self.head == nil {
            return nil
        }
        return self.head!.value
    }
    
    func size() -> Int {
        return self.count
    }
    
    func isEmpty() -> Bool {
        return self.count == 0
    }
    
    func clear() {
        self.head = nil
        self.tail = nil
        DispatchQueue.main.async {
            self.count = 0
        }
    }
}

class QueueNode<T> {
    var prev: QueueNode<T>?
    var next: QueueNode<T>?
    let value: T
    
    init(value: T) {
        self.value = value
        self.next = nil
        self.prev = nil
    }
    
    func insertAfter(newQueueNode: QueueNode<T>) {
        if self.next == nil {
            self.next = newQueueNode
            newQueueNode.prev = self
        } else {
            newQueueNode.next = self.next
            newQueueNode.next!.prev = newQueueNode
            newQueueNode.prev = self
            self.next = newQueueNode
        }
    }
    func insertBefore(newQueueNode: QueueNode<T>) {
        if self.prev == nil {
            self.prev = newQueueNode
            newQueueNode.next = self
        } else {
            newQueueNode.prev = self.prev
            newQueueNode.prev!.next = newQueueNode
            newQueueNode.next = self
            self.prev = newQueueNode
        }
    }
}
