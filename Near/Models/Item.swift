//
//  Item.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import Foundation
import SwiftData

@Model
final class DetectedDevice {
    @Attribute(.unique) var id: UUID
    var deviceId: String
    var name: String
    var type: String // "rayban_meta", "vision_pro", "snap_spectacles", "unknown"
    var timestamp: Date
    var rssi: Int
    var isStarred: Bool
    var threatLevel: String // "High", "Medium", "Low"
    var isSimulated: Bool
    
    init(id: UUID = UUID(), deviceId: String, name: String, type: String, timestamp: Date = Date(), rssi: Int = -80, isStarred: Bool = false, threatLevel: String = "Medium", isSimulated: Bool = false) {
        self.id = id
        self.deviceId = deviceId
        self.name = name
        self.type = type
        self.timestamp = timestamp
        self.rssi = rssi
        self.isStarred = isStarred
        self.threatLevel = threatLevel
        self.isSimulated = isSimulated
    }
}
