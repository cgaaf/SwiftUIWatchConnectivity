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
    var syncronizer = WCSession.syncronizer
    
    var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var count: Int = 0
    @Published private(set) var lastChangedBy: Device = .this
    
    init() {
        let stream = syncronizer.receive(type: Int.self)
        
        stream
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("THere was an error after decode: \(error.localizedDescription)")
                case .finished:
                    print("This publisher completed: Shouldn't happen")
                }
            } receiveValue: { int in
                self.count = int
            }
            .store(in: &cancellables)
        
        syncronizer.device.assign(to: &$lastChangedBy)
    }
    
    func increment() {
        count += 1
        send()
    }
    
    func decrement() {
        count -= 1
        send()
    }
    
    func send() {
        syncronizer.send(count)
    }
}

enum Device {
    case this, that
}
