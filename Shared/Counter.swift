//
//  Counter.swift
//  WatchConnectivityPrototype
//
//  Created by Chris Gaafary on 4/18/21.
//

import Foundation
import Combine
import WatchConnectivity

final class Counter: ObservableObject {
    let syncedSession: SyncedSession = .shared
    @Published private(set) var count: Int = 0
    
    func increment() {
        count += 1
        let data: [String: Any] = ["count" : count, "id": UUID().uuidString]
        syncedSession.updateContext(data)
    }
    
    func decrement() {
        count -= 1
        syncedSession.updateContext(["count" : count])
    }
}
