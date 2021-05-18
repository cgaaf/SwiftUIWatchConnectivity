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
    @SyncedWatchState("Key") var count: Int = 0
    
    func increment() {
        count += 1
    }
    
    func decrement() {
        count -= 1
    }
}

//final class Counter: ObservableObject {
//    let syncedSession: SyncedSession = .shared
//    @Published private(set) var count: Int = 0
//
//    init() {
//        syncedSession
//            .publisher
//            .compactMap { $0["count"] as? Data }
//            .decode(type: Int.self, decoder: JSONDecoder())
//            .replaceError(with: 0)
//            .receive(on: DispatchQueue.main)
//            .assign(to: &$count)
//    }
//
//    func increment() {
//        count += 1
//        let encoded = try! JSONEncoder().encode(count)
//        let data: [String: Any] = ["count" : encoded]
//        syncedSession.updateContext(data)
//    }
//
//    func decrement() {
//        count -= 1
//        let encoded = try! JSONEncoder().encode(count)
//        let data: [String: Any] = ["count" : encoded]
//        syncedSession.updateContext(data)
//    }
//}
