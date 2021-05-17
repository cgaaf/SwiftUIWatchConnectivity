//
//  SessionDelegator.swift
//  WatchConnectivityPrototype
//
//  Created by Chris Gaafary on 4/15/21.
//

import Combine
import WatchConnectivity

class SessionDelegater: NSObject, WCSessionDelegate {
//    static let shared = SessionDelegater()
//
//    let anySubject = PassthroughSubject<Any?, Never>()
//
//    var sessionPubisher: AnyPublisher<Any?, Never> {
//        anySubject
//            .eraseToAnyPublisher()
//    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Protocol comformance only
        // Not needed for this demo
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received new context!")
        
//        let data = applicationContext["data"]
        DispatchQueue.main.async {
//            self.anySubject.send(data)
        }
    }
    
    // iOS Protocol comformance
    // Not needed for this demo otherwise
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    #endif
    
}
