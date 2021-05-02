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
        
        @Published var dateLastChanged = Date()
        var latestPacketSent: Data?
        
        var timerSubscription: AnyCancellable?
        
        // PUBLISHERS
        private let dataSubject = PassthroughSubject<Data, Never>()
        private let deviceSubject = PassthroughSubject<Device, Never>()
        
        // PUBLISHERS
        var device: AnyPublisher<Device, Never> {
            deviceSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        init(session: WCSession = .default) {
            self.delegate = SessionDelegater(subject: dataSubject)
            self.session = session
            self.session.delegate = self.delegate
            self.session.activate()
        }
        
        func send<T: Codable>(_ data: T) {
            updateLastChange()
            
            let dataPacket = DataPacket(dateLastChanged: dateLastChanged, creationDate: Date(), data: data)
            let encoded = try! JSONEncoder().encode(dataPacket)
            latestPacketSent = encoded
            
            if session.isReachable {
                transmit(encoded)
            } else {
                print("Session not current reachable, starting timer")
                timerSubscription = Timer.publish(every: 2, on: .main, in: .default)
                    .autoconnect()
                    .sink { _ in
                        if let latestPacketSent = self.latestPacketSent {
                            self.transmit(latestPacketSent)
                        }
                    }
            }
        }
        
        private func transmit(_ data: Data) {
            print("Transmitting")
            session.sendMessageData(data) { _ in
                print("Succesul transfer: Cancel timer")
                self.timerSubscription?.cancel()
            } errorHandler: { error in
                print(error.localizedDescription)
            }
        }
        
        func updateLastChange() {
            dateLastChanged = Date()
            deviceSubject.send(.this)
        }
        
        func receive<T: Codable>(type: T.Type) -> AnyPublisher<T, Error> {
            dataSubject
                .removeDuplicates()
                .decode(type: DataPacket<T>.self, decoder: JSONDecoder())
                .handleEvents(receiveOutput: { dataPacket in
                    if self.dateLastChanged < dataPacket.dateLastChanged {
                        self.deviceSubject.send(.that)
                    }
                })
                .filter({ dataPacket in
                    self.dateLastChanged < dataPacket.dateLastChanged
                })
                .map(\.data)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    }
}
