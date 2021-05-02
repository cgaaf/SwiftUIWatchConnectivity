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
    @SyncWrapper var syncedCount: Int
    
    var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var count: Int = 0
    @Published private(set) var lastChangedBy: WCSession.Device = .thisDevice
    
    init() {
        _syncedCount = SyncWrapper(wrappedValue: 0)
        _syncedCount.mostRecentDataChangedByDevice.assign(to: &$lastChangedBy)

        $syncedCount
            .sink { _ in
                print("There was a problem")
            } receiveValue: { int in
                self.count = int
            }
            .store(in: &cancellables)
    }
    
    func increment() {
        syncedCount += 1
    }
    
    func decrement() {
        syncedCount -= 1
    }
}
