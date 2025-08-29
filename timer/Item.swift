//
//  Item.swift
//  timer
//
//  Created by taylor drew on 8/29/25.
//

import Foundation
import SwiftData

@Model
final class Item: Identifiable {
    var id = UUID()
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
