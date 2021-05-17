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
    
    let subject = PassthroughSubject<[String : Any], Never>()
    
    var publisher: AnyPublisher<[String : Any], Never> {
        subject
            .handleEvents(receiveOutput: { _ in
                print("Received passthrough")
            })
            .eraseToAnyPublisher()
    }
    
    private override init() {
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func updateContext(_ applicationContext: [String : Any]) {
        try! session.updateApplicationContext(applicationContext)
        
        session.sendMessage(applicationContext, replyHandler: nil, errorHandler: nil)
        
        print("Context and message sent")
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Activation state changed to \(activationState)")
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received new context")
        dump(applicationContext)
        
        subject.send(applicationContext)
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Recieved a message")
        dump(session.receivedApplicationContext)
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
