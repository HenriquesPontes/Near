//
//  NearActivityAttributes.swift
//  Near
//

import ActivityKit
import Foundation

struct NearActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var isScanning: Bool
        var detectedCount: Int
        var nearestDeviceName: String?
        var nearestDeviceType: String?
        var nearestDeviceDistance: Double?
        var threatLevel: String?
    }

    var activityTitle: String
}
