//
//  SyncWrapper.swift
//  SwiftUIWatchConnectivity
//
//  Created by Chris Gaafary on 5/1/21.
//

import Foundation
import WatchConnectivity
import Combine

extension WCSession {
    enum Device { case thisDevice, otherDevice }
}

@propertyWrapper class SyncWrapper<T: Codable> {
    var session: WCSession
    let delegate: WCSessionDelegate
    
    var cancellables = Set<AnyCancellable>()
    
    // SUBJECTS
    private let dataSubject = PassthroughSubject<Data, Never>()
    private let deviceSubject = PassthroughSubject<WCSession.Device, Never>()
    private let valueSubject: CurrentValueSubject<T, Error>
    
    // SYNC TIMER RELATED
    let timer: Timer.TimerPublisher
    var timerSubscription: AnyCancellable?
    
    // PUBLISHERS
    var mostRecentDataChangedByDevice: AnyPublisher<WCSession.Device, Never> {
        deviceSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // INTERNAL RECORD KEEPING
    // THIS HELPS PREVENT UNNECCESARY AND DUPLICATE NETWORK REQUESTS
    var dateLastChanged = Date()
    var latestPacketSent: Data?
    
    var receivedData: AnyPublisher<T, Error> {
        dataSubject
            .removeDuplicates()
            .decode(type: SyncedWatchObject<T>.self, decoder: JSONDecoder())
            .handleEvents(receiveOutput: { dataPacket in
                print("Received data")
                if self.dateLastChanged < dataPacket.dateModified {
                    self.deviceSubject.send(.otherDevice)
                }
            })
            .filter({ dataPacket in
                self.dateLastChanged < dataPacket.dateModified
            })
            .map(\.object)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    var wrappedValue: T {
        get { valueSubject.value }
        set {
            send(newValue)
            valueSubject.value = newValue
        }
    }
    
    var projectedValue: CurrentValueSubject<T, Error> {
        get { valueSubject }
    }
    
    init(wrappedValue: T, session: WCSession = .default, autoRetryFor timeInterval: TimeInterval = 2) {
        self.delegate = SessionDelegater(subject: dataSubject)
        self.session = session
        self.session.delegate = self.delegate
        self.session.activate()
        
        self.timer = Timer.publish(every: timeInterval, on: .main, in: .default)
        
        self.valueSubject = CurrentValueSubject(wrappedValue)
        
        receivedData
            .sink(receiveCompletion: valueSubject.send, receiveValue: valueSubject.send)
            .store(in: &cancellables)

    }
    
    func send(_ data: T) {
        updateLastChange()
        
        let dataPacket = SyncedWatchObject(dateModified: dateLastChanged, object: data)
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
}
