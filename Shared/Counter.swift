//
//  Counter.swift
//  WatchConnectivityPrototype
//
//  Created by Chris Gaafary on 4/18/21.
//

import Foundation
import Combine
import WatchSync

final class Counter: ObservableObject {
    @SyncedWatchState var syncedCount: Int
    
    var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var count: Int = 0
    @Published private(set) var lastChangedBy: Device = .thisDevice
    
    init() {
        _syncedCount = SyncedWatchState(wrappedValue: 0)
        _syncedCount.mostRecentDataChangedByDevice.assign(to: &$lastChangedBy)

        $syncedCount
            .breakpointOnError()
            .replaceError(with: count)
            .assign(to: &$count)
    }
    
    func increment() {
        syncedCount += 1
    }
    
    func decrement() {
        syncedCount -= 1
    }
}
