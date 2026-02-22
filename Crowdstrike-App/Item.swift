//
//  Item.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import Foundation
import SwiftData

// Keeping Item for potential local caching/favorites functionality
// The main Host data comes from the CrowdStrike API

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
