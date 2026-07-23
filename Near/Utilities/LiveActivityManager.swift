//
//  LiveActivityManager.swift
//  Near
//

import ActivityKit
import Foundation
import Combine

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<NearActivityAttributes>? = nil
    
    private init() {}
    
    func startActivity(isScanning: Bool, detectedDevices: [BluetoothDevice]) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        if currentActivity != nil {
            updateActivity(isScanning: isScanning, detectedDevices: detectedDevices)
            return
        }
        
        let initialContentState = createContentState(isScanning: isScanning, detectedDevices: detectedDevices)
        let attributes = NearActivityAttributes(activityTitle: "Near Radar Scan")
        
        do {
            let activity = try Activity<NearActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(isScanning: Bool, detectedDevices: [BluetoothDevice]) {
        guard let activity = currentActivity else {
            if isScanning {
                startActivity(isScanning: isScanning, detectedDevices: detectedDevices)
            }
            return
        }
        
        let state = createContentState(isScanning: isScanning, detectedDevices: detectedDevices)
        
        Task {
            await activity.update(
                ActivityContent<NearActivityAttributes.ContentState>(
                    state: state,
                    staleDate: Date().addingTimeInterval(30)
                )
            )
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
    
    private func createContentState(isScanning: Bool, detectedDevices: [BluetoothDevice]) -> NearActivityAttributes.ContentState {
        let sorted = detectedDevices.sorted { (d1, d2) -> Bool in
            return d1.rssi > d2.rssi
        }
        
        let nearest = sorted.first
        
        return NearActivityAttributes.ContentState(
            isScanning: isScanning,
            detectedCount: detectedDevices.count,
            nearestDeviceName: nearest?.name,
            nearestDeviceType: nearest?.type,
            nearestDeviceDistance: nearest?.estimatedDistance,
            threatLevel: nearest?.threatLevel
        )
    }
}
