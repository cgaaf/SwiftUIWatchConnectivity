//
//  DataPacket.swift
//  SwiftUIWatchConnectivity
//
//  Created by Chris Gaafary on 4/29/21.
//

import Foundation

struct DataPacket<T: Codable>: Codable {
    let dateLastChanged: Date
    let data: T
}
