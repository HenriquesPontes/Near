//
//  PerformanceMonitor.swift
//  Near
//

import Foundation
import MetricKit

@MainActor
class PerformanceMonitor: NSObject, MXMetricManagerSubscriber {
    static let shared = PerformanceMonitor()
    
    private override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }
    
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            let jsonRepresentation = payload.jsonRepresentation()
            Task { @MainActor in
                AnalyticsManager.shared.trackMetrics(payloadData: jsonRepresentation)
            }
        }
    }
    
    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let jsonRepresentation = payload.jsonRepresentation()
            Task { @MainActor in
                AnalyticsManager.shared.trackDiagnostics(payloadData: jsonRepresentation)
            }
        }
    }
}
