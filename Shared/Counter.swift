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
    var session: WCSession
    let delegate: WCSessionDelegate
    let subject = PassthroughSubject<Data, Never>()
    
    var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var count: Int = 0
    @Published private(set) var lastChangedBy: Device = .this
    @Published private(set) var dateLastChanged = Date()
    
    init(session: WCSession = .default) {
        self.delegate = SessionDelegater(subject: subject)
        self.session = session
        self.session.delegate = self.delegate
        self.session.activate()
        
        subject
            .decode(type: DataPacket<Int>.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    print("THere was an error after decode: \(error.localizedDescription)")
                case .finished:
                    print("This publisher completed: SHouldn't happen")
                }
            } receiveValue: { packet in
                let comparison = self.dateLastChanged.compare(packet.dateLastChanged)
                if comparison == .orderedAscending {
                    print("That is more recent, updating...")
                    self.count = packet.data
                    self.lastChangedBy = .that
                } else {
                    print("This is more recent, no update")
                }
            }
            .store(in: &cancellables)
        
        Timer.publish(every: 2, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                self.send()
            }
            .store(in: &cancellables)

    }
    
    func increment() {
        count += 1
        logChange()
        send()
    }
    
    func decrement() {
        count -= 1
        logChange()
        send()
    }
    
    func logChange() {
        lastChangedBy = .this
        dateLastChanged = Date()
    }
    
    func send() {
        let sendPacket = DataPacket(dateLastChanged: dateLastChanged, data: count)
        let data = try! JSONEncoder().encode(sendPacket)
        
        session.sendMessageData(data, replyHandler: nil) { error in
            print(error.localizedDescription)
        }

    }
}

enum Device {
    case this, that
}
