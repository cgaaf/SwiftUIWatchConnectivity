//
//  SessionDelegator.swift
//  WatchConnectivityPrototype
//
//  Created by Chris Gaafary on 4/15/21.
//

import Combine
import WatchConnectivity

class SessionDelegater: NSObject, WCSessionDelegate {
    let subject: PassthroughSubject<Data, Never>
    
    init(subject: PassthroughSubject<Data, Never>) {
        self.subject = subject
        super.init()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Protocol comformance only
        // Not needed for this demo
    }
    
//    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
//        DispatchQueue.main.async {
//            if let count = message["count"] as? Int {
//                self.countSubject.send(count)
//            } else {
//                print("There was an error")
//            }
//        }
//    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        self.subject.send(messageData)
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
