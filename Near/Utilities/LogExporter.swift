//
//  LogExporter.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import Foundation

class PersistentLogger {
    static let shared = PersistentLogger()
    
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.near.persistentlogger")
    
    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent("NearPersistentLog.csv")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "Timestamp,Log Type,Device Name,Device Type,RSSI (dBm),Threat Level,Device ID,Starred,Activity Message\n"
            try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    func logDetection(_ device: DetectedDevice) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let ts = formatter.string(from: device.timestamp)
            
            let name = self.escapeCSVField(device.name)
            let type = displayNameForType(device.type, manufacturer: device.manufacturer)
            let rssi = "\(device.rssi)"
            let threat = device.threatLevel
            let deviceId = self.escapeCSVField(device.deviceId)
            let starred = device.isStarred ? "Yes" : "No"
            
            let line = "\(ts),Detection,\(name),\(type),\(rssi),\(threat),\(deviceId),\(starred),\n"
            self.append(line)
        }
    }
    
    func logActivity(_ message: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let ts = formatter.string(from: Date())
            let msg = self.escapeCSVField(message)
            
            let line = "\(ts),Activity,,,,,,,\(msg)\n"
            self.append(line)
        }
    }
    
    private func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: fileURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                try? data.write(to: fileURL)
            }
        }
    }
    
    func exportCSV() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("near_log_\(Date().timeIntervalSince1970).csv")
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: tempURL)
            return tempURL
        } catch {
            print("Failed to copy persistent log for export: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
}
