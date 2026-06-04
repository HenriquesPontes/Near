//
//  AnalyticsManager.swift
//  Near
//
//  Created by Supabase Integration
//

import Foundation
import Supabase

struct AnalyticsEvent: Codable {
    let event_name: String
    let device_id: String
    let threat_level: Int16
    let manufacturer: String
    let device_type: String
}

@MainActor
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://tjtmxozfvpyzlcpqzjoz.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqdG14b3pmdnB5emxjcHF6am96Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1NDA3MTUsImV4cCI6MjA5NjExNjcxNX0.-sKF45522m4WSPebfnjnLvtneuJRcX8r2arZj0vlYgg"
        
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    func trackDetection(device: BluetoothDevice) {
        // Map threat level to Int16: "High" -> 2, "Medium" -> 1, "Low"/other -> 0
        let threatLevelInt: Int16 = {
            switch device.threatLevel.lowercased() {
            case "high": return 2
            case "medium": return 1
            default: return 0
            }
        }()
        
        let event = AnalyticsEvent(
            event_name: "device_detected",
            device_id: device.deviceId,
            threat_level: threatLevelInt,
            manufacturer: device.manufacturer ?? "Unknown",
            device_type: device.type
        )
        
        Task {
            do {
                try await client
                    .from("analytics_events")
                    .insert(event)
                    .execute()
                print("Analytics: Successfully logged detection of \(device.name)")
            } catch {
                print("Analytics error logging detection: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - MetricKit Tracking
    
    struct MetricPayloadEvent: Codable {
        let payload: AnyJSON
    }
    
    func trackMetrics(payloadData: Data) {
        guard let json = try? JSONDecoder().decode(AnyJSON.self, from: payloadData) else {
            return
        }
        
        let event = MetricPayloadEvent(payload: json)
        
        Task {
            do {
                try await client
                    .from("metric_payloads")
                    .insert(event)
                    .execute()
                print("Analytics: Successfully logged metric payload")
            } catch {
                print("Analytics error logging metrics: \(error.localizedDescription)")
            }
        }
    }
    
    func trackDiagnostics(payloadData: Data) {
        guard let json = try? JSONDecoder().decode(AnyJSON.self, from: payloadData) else {
            return
        }
        
        let event = MetricPayloadEvent(payload: json)
        
        Task {
            do {
                try await client
                    .from("diagnostic_payloads")
                    .insert(event)
                    .execute()
                print("Analytics: Successfully logged diagnostic payload")
            } catch {
                print("Analytics error logging diagnostics: \(error.localizedDescription)")
            }
        }
    }
}
