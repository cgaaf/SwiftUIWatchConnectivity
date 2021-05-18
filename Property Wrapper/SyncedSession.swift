//
//  SyncedSession.swift
//  SwiftUIWatchConnectivity
//
//  Created by Chris Gaafary on 5/16/21.
//

import Foundation
import Combine
import WatchConnectivity

class SyncedSession: NSObject, WCSessionDelegate {
    static let shared = SyncedSession()
    
    let session: WCSession = .default
    
    private let subject = PassthroughSubject<[String : Any], Never>()
    
    var publisher: AnyPublisher<[String : Any], Never> {
        subject
            .eraseToAnyPublisher()
    }
    
    private override init() {
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func updateContext(_ applicationContext: [String : Any]) {
        do {
            try session.updateApplicationContext(applicationContext)
        } catch {
            print("There was an error updating the applicationContext: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        //
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        subject.send(applicationContext)
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // For iOS only
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // For iOS only
    }
    #endif
}
