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
    
    init(wrappedValue: Value, _ key: String) {
        thisDevice = CurrentValueSubject(wrappedValue)
        
        let sharedPublisher = otherDevice
            .share()
            
        sharedPublisher
            .encode(encoder: JSONEncoder())
            .assertNoFailure()
            .map { [key: $0] }
            .sink(receiveValue: syncedSession.updateContext)
            .store(in: &subscriptions)
        
        sharedPublisher
            .subscribe(thisDevice)
            .store(in: &subscriptions)

        syncedSession
            .publisher
            .compactMap{ $0[key] as? Data }
            .decode(type: Value.self, decoder: JSONDecoder())
            .assertNoFailure()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [unowned self] _ in
                observableObjectPublisher?.send()
            })
            .subscribe(thisDevice)
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
