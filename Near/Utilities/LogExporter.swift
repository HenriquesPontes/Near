//
//  LogExporter.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import Foundation

/// Generates a CSV string from an array of DetectedDevice records
/// for exporting the detection log history.
struct LogExporter {
    
    static func generateCSV(from devices: [DetectedDevice]) -> String {
        var csv = "Timestamp,Device Name,Device Type,RSSI (dBm),Threat Level,Device ID,Starred\n"
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        for device in devices {
            let timestamp = formatter.string(from: device.timestamp)
            let name = escapeCSVField(device.name)
            let type = displayNameForType(device.type)
            let rssi = "\(device.rssi)"
            let threat = device.threatLevel
            let deviceId = escapeCSVField(device.deviceId)
            let starred = device.isStarred ? "Yes" : "No"
            
            csv += "\(timestamp),\(name),\(type),\(rssi),\(threat),\(deviceId),\(starred)\n"
        }
        
        return csv
    }
    
    /// Escapes a CSV field value — wraps in quotes if it contains commas, quotes, or newlines.
    private static func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
