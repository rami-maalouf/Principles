//
//  Item.swift
//  Principles
//
//  Created by Rami Maalouf on 2026-03-10.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
