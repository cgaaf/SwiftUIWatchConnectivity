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
    static func getSyncronizer<T: Codable>(type: T.Type) -> Syncronizer<T> {
        return Syncronizer(type: T.self)
    }
    
    final class Syncronizer<T: Codable> {
        var session: WCSession
        let delegate: WCSessionDelegate
        
        // Internal record keeping
        var dateLastChanged = Date()
        var latestPacketSent: Data?
        
        // SYNC TIMER RELATED
        let timer: Timer.TimerPublisher
        var timerSubscription: AnyCancellable?
        
        // SUBJECTS
        private let dataSubject = PassthroughSubject<Data, Never>()
        private let deviceSubject = PassthroughSubject<Device, Never>()
        
        // PUBLISHERS
        var mostRecentDataChangedByDevice: AnyPublisher<Device, Never> {
            deviceSubject
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        var receivedData: AnyPublisher<T, Error> {
            dataSubject
                .removeDuplicates()
                .decode(type: DataPacket<T>.self, decoder: JSONDecoder())
                .handleEvents(receiveOutput: { dataPacket in
                    if self.dateLastChanged < dataPacket.dateLastChanged {
                        self.deviceSubject.send(.otherDevice)
                    }
                })
                .filter({ dataPacket in
                    self.dateLastChanged < dataPacket.dateLastChanged
                })
                .map(\.data)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
        
        init<T: Codable>(session: WCSession = .default, syncTime: TimeInterval = 2, type: T.Type) {
            self.delegate = SessionDelegater(subject: dataSubject)
            self.session = session
            self.session.delegate = self.delegate
            self.session.activate()
            
            self.timer = Timer.publish(every: syncTime, on: .main, in: .default)
        }
        
        func send(_ data: T) {
            updateLastChange()
            
            let dataPacket = DataPacket(dateLastChanged: dateLastChanged, creationDate: Date(), data: data)
            let encoded = try! JSONEncoder().encode(dataPacket)
            latestPacketSent = encoded
            
            if session.isReachable {
                transmit(encoded)
            } else {
                print("Session not current reachable, starting timer")
                timerSubscription = timer
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
            deviceSubject.send(.thisDevice)
        }
        
        func receive<T: Codable>(type: T.Type) -> AnyPublisher<T, Error> {
            dataSubject
                .removeDuplicates()
                .decode(type: DataPacket<T>.self, decoder: JSONDecoder())
                .handleEvents(receiveOutput: { dataPacket in
                    if self.dateLastChanged < dataPacket.dateLastChanged {
                        self.deviceSubject.send(.otherDevice)
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
