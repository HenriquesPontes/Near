//
//  LocationManager.swift
//  Near
//

import Foundation
internal import CoreLocation
import Combine
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var isInSafeZone: Bool = false
    
    // Geofence preferences
    @AppStorage("isGeofenceEnabled") var isGeofenceEnabled: Bool = false {
        didSet {
            if let loc = lastKnownLocation {
                checkGeofence(location: loc)
            }
        }
    }
    @AppStorage("safeZoneLat") var safeZoneLat: Double = 0.0
    @AppStorage("safeZoneLon") var safeZoneLon: Double = 0.0
    @AppStorage("safeZoneRadius") var safeZoneRadius: Double = 150.0 // 150 meters default
    
    var hasSetSafeZone: Bool {
        return safeZoneLat != 0.0 || safeZoneLon != 0.0
    }
    
    private var lastKnownLocation: CLLocation?
    
    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 30 // update every 30 meters
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastKnownLocation = location
        DispatchQueue.main.async {
            self.currentLocation = location.coordinate
            self.checkGeofence(location: location)
        }
    }
    
    func setHomeLocation() {
        guard let coord = currentLocation else { return }
        safeZoneLat = coord.latitude
        safeZoneLon = coord.longitude
        if let loc = lastKnownLocation {
            checkGeofence(location: loc)
        }
    }
    
    func clearHomeLocation() {
        safeZoneLat = 0.0
        safeZoneLon = 0.0
        isInSafeZone = false
    }
    
    private func checkGeofence(location: CLLocation) {
        guard isGeofenceEnabled, hasSetSafeZone else {
            if isInSafeZone {
                isInSafeZone = false
            }
            return
        }
        
        let safeZoneLoc = CLLocation(latitude: safeZoneLat, longitude: safeZoneLon)
        let distance = location.distance(from: safeZoneLoc)
        
        let nowInSafeZone = distance <= safeZoneRadius
        
        if nowInSafeZone != isInSafeZone {
            isInSafeZone = nowInSafeZone
            
            if nowInSafeZone {
                // Pause scan inside safe zone
                BluetoothManager.shared.stopScanning()
            } else {
                // Resume scan in public area outside safe zone
                BluetoothManager.shared.startScanning()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager failed: \(error.localizedDescription)")
    }
}
