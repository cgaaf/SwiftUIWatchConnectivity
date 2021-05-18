//
//  SyncedWatchState.swift
//  SwiftUIWatchConnectivity
//
//  Created by Chris Gaafary on 5/17/21.
//

import Foundation
import SwiftUI
import Combine

typealias Syncable = Codable & Equatable

@propertyWrapper
class SyncedWatchState<Value: Syncable> {
    static subscript<T: ObservableObject>(
        _enclosingInstance instance: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, SyncedWatchState>
    ) -> Value {
        get {
            let enclosingInstance = instance[keyPath: storageKeyPath]
            let publisher = instance.objectWillChange as! ObservableObjectPublisher
            enclosingInstance.observableObjectPublisher = publisher
            
            
            let value = enclosingInstance.thisDevice.value
            print("Getting value \(value)")
            
            return value
        }
        set {
            let enclosingInstance = instance[keyPath: storageKeyPath]
            
            print("Setting new value \(newValue)")
            enclosingInstance.observableObjectPublisher?.send()
            enclosingInstance.otherDevice.send(newValue)
        }
    }
    
    
    
    let syncedSession: SyncedSession = .shared
    let thisDevice: CurrentValueSubject<Value, Never>
    let otherDevice = PassthroughSubject<Value, Never>()
    
    var observableObjectPublisher: ObservableObjectPublisher?
    var subscriptions = Set<AnyCancellable>()
    
    init(wrappedValue: Value) {
        print("Initializing")
        thisDevice = CurrentValueSubject(wrappedValue)
        
        let pub = otherDevice
            .share()
            
        pub
            .encode(encoder: JSONEncoder())
            .map { encoded in
                ["data": encoded]
            }
            .sink { completion in
                // later
            } receiveValue: { [unowned self] context in
                print("Syncronizing context")
                syncedSession.updateContext(context)
            }
            .store(in: &subscriptions)
        
        pub
            .subscribe(thisDevice)
            .store(in: &subscriptions)


        
        syncedSession
            .publisher
            .compactMap{ $0["data"] as? Data }
            .decode(type: Value.self, decoder: JSONDecoder())
            .removeDuplicates()
            .replaceError(with: thisDevice.value)
            .receive(on: DispatchQueue.main)
//            .subscribe(thisDevice)
            .sink(receiveValue: { newValue in
                self.observableObjectPublisher?.send()
                self.thisDevice.send(newValue)
            })
            .store(in: &subscriptions)
    }
    
    @available(*, unavailable,
    message: "This property wrapper can only be applied to classes"
    )
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }
}
