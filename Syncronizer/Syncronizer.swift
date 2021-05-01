//
//  DeviceSyncronizer.swift
//  SwiftUIWatchConnectivity
//
//  Created by Chris Gaafary on 4/30/21.
//

import Foundation
import Combine
import WatchConnectivity

extension WCSession {
    static let syncronizer: Syncronizer = Syncronizer()
    
    final class Syncronizer {
        var session: WCSession
        let delegate: WCSessionDelegate
        
        var dateLastChanged = Date()
        var lastChangedBy: Device = .this
        var latestPacketSent = Data()
        
        var cancellables = Set<AnyCancellable>()
        
        // PUBLISHERS
        private let subject = PassthroughSubject<Data, Never>()
        let devicePublisher = PassthroughSubject<Device, Never>()
        let lastDatePublisher = PassthroughSubject<Date, Never>()
        
        init(session: WCSession = .default) {
            self.delegate = SessionDelegater(subject: subject)
            self.session = session
            self.session.delegate = self.delegate
            self.session.activate()
            
            Timer.publish(every: 4, on: .main, in: .default)
                .autoconnect()
                .sink { _ in
                    if self.latestPacketSent.isEmpty == false {
                        self.transmit(self.latestPacketSent)
                    }
                }
                .store(in: &cancellables)
        }
        
        func send<T: Codable>(_ data: T) {
            updateLastChange()
            updateLastChangedBy(to: .this)
            
            let dataPacket = DataPacket(dateLastChanged: dateLastChanged, creationDate: Date(), data: data)
            let encoded = try! JSONEncoder().encode(dataPacket)
            latestPacketSent = encoded
            
            transmit(encoded)
        }
        
        private func transmit(_ data: Data) {
            session.sendMessageData(data, replyHandler: nil) { error in
                print(error.localizedDescription)
            }
            
            session.sendMessageData(data) { error in
                print("There was an error sending data")
            }

        }
        
        func updateLastChangedBy(to device: Device) {
            self.lastChangedBy = device
            devicePublisher.send(lastChangedBy)
        }
        
        func updateLastChange() {
            dateLastChanged = Date()
            lastDatePublisher.send(dateLastChanged)
        }
        
        func receive<T: Codable>(type: T.Type) -> AnyPublisher<T, Error> {
            subject
                .handleEvents(receiveOutput: { _ in
                    print("Received data")
                })
                .removeDuplicates()
                .handleEvents(receiveOutput: { _ in
                    print("Received new data")
                })
                .receive(on: DispatchQueue.main)
                .decode(type: DataPacket<T>.self, decoder: JSONDecoder())
                .filter({ dataPacket in
                    let comparison = self.dateLastChanged.compare(dataPacket.dateLastChanged)
                    if comparison == .orderedAscending {
                        print("That is more recent, updating...")
                        self.updateLastChangedBy(to: .that)
                        return true
                    } else {
                        print("This is more recent, no update")
                        return false
                    }
                })
                .map(\.data)
                .eraseToAnyPublisher()
        }
    }
}
