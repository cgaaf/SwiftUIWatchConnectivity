//
//  DataPacket.swift
//  SwiftUIWatchConnectivity
//
//  Created by Chris Gaafary on 4/29/21.
//

import Foundation

struct SyncedWatchObject<T: Codable>: Codable {
    let dateModified: Date
    let object: T
}
