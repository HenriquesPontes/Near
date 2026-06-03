//
//  BluetoothManager.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import Foundation
import CoreBluetooth
internal import CoreLocation
import UserNotifications
import Combine
import SwiftUI

struct BluetoothDevice: Identifiable, Hashable {
    var id: UUID = UUID()
    var deviceId: String
    var name: String
    var type: String // "rayban_meta", "vision_pro", "snap_spectacles", "unknown"
    var rssi: Int
    var lastSeen: Date = Date()
    var isStarred: Bool = false
    var isSimulated: Bool = false
    
    var threatLevel: String {
        switch type {
        case "rayban_meta", "vision_pro":
            return "High"
        case "snap_spectacles":
            return "High"
        default:
            return "Medium"
        }
    }
    
    var estimatedDistance: Double {
        // Distance calculation based on RSSI
        // TxPower at 1m is typically -59dBm
        let txPower = -59.0
        if rssi == 0 {
            return -1.0
        }
        let ratio = Double(rssi) * 1.0 / txPower
        if ratio < 1.0 {
            return pow(ratio, 10.0)
        } else {
            return (0.89976) * pow(ratio, 7.7095) + 0.111
        }
    }
}

class BluetoothManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = BluetoothManager()
    
    @Published var detectedDevices: [BluetoothDevice] = []
    @Published var isScanning: Bool = false
    @Published var activeNotification: BluetoothDevice? = nil
    
    // Persisted settings via UserDefaults
    @AppStorage("alertOnNewDevices") var alertOnNewDevices: Bool = true
    @AppStorage("rssiThreshold") var rssiThreshold: Int = -75
    @AppStorage("autoStartScanning") var autoStartScanning: Bool = false
    @AppStorage("continueScanInBackground") var continueScanInBackground: Bool = true {
        willSet {
            objectWillChange.send()
        }
        didSet {
            if continueScanInBackground {
                if !isScanning {
                    startScanning()
                }
            } else {
                if isScanning {
                    stopScanning()
                }
            }
        }
    }
    @AppStorage("appAppearance") var appAppearance: String = "system"
    @AppStorage("notificationCooldown") var notificationCooldown: Double = 10000.0 {
        willSet {
            objectWillChange.send()
        }
    }
    
    // enabledAlertTypes persisted as JSON string since @AppStorage doesn't support Set<String>
    var enabledAlertTypes: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: "enabledAlertTypes") ?? ""
            if raw.isEmpty {
                return ["rayban_meta", "vision_pro", "snap_spectacles", "unknown"]
            }
            let arr = (try? JSONDecoder().decode([String].self, from: Data(raw.utf8))) ?? []
            return Set(arr)
        }
        set {
            let arr = Array(newValue)
            if let data = try? JSONEncoder().encode(arr), let str = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(str, forKey: "enabledAlertTypes")
            }
            objectWillChange.send()
        }
    }
    
    // ignoredDevices maps deviceId (String) to a human-readable display string
    var ignoredDevices: [String: String] {
        get {
            let raw = UserDefaults.standard.string(forKey: "ignoredDevices") ?? ""
            if raw.isEmpty {
                return [:]
            }
            return (try? JSONDecoder().decode([String: String].self, from: Data(raw.utf8))) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue), let str = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(str, forKey: "ignoredDevices")
            }
            objectWillChange.send()
        }
    }
    
    func ignoreDevice(id: String, name: String) {
        var currentIgnored = ignoredDevices
        currentIgnored[id] = name
        ignoredDevices = currentIgnored
        
        // Remove from the live scanned list immediately
        DispatchQueue.main.async {
            self.detectedDevices.removeAll(where: { $0.deviceId == id })
        }
    }
    
    func unignoreDevice(id: String) {
        var currentIgnored = ignoredDevices
        currentIgnored.removeValue(forKey: id)
        ignoredDevices = currentIgnored
    }
    
    private var centralManager: CBCentralManager?
    private var locationManager: CLLocationManager?
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    #if os(iOS)
    @Published var backgroundRefreshStatus: UIBackgroundRefreshStatus = .available
    #endif
    private var lastNotifiedTimes: [String: Date] = [:]
    private var cleanupTimer: Timer?
    
    override init() {
        super.init()
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        requestLocationPermission()
        
        #if os(iOS)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackgroundRefreshStatusChange), name: UIApplication.backgroundRefreshStatusDidChangeNotification, object: nil)
        self.backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        #endif
        
        // Auto-start scanning on launch if scan toggle is enabled
        if continueScanInBackground {
            isScanning = true
            startCleanupTimer()
        }
    }
    
    deinit {
        cleanupTimer?.invalidate()
    }
    
    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        let status = CLLocationManager.authorizationStatus()
        locationAuthorizationStatus = status
        if status == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAuthorizationStatus = status
    }
    
    #if os(iOS)
    @objc private func handleDidEnterBackground() {
        if continueScanInBackground && isScanning {
            // Transition scanning to background-compatible mode using specific service UUIDs
            centralManager?.stopScan()
            let backgroundServices = [
                CBUUID(string: "180F"), // Battery Service
                CBUUID(string: "180A"), // Device Information
                CBUUID(string: "FEAA")  // Eddystone
            ]
            centralManager?.scanForPeripherals(withServices: backgroundServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    @objc private func handleWillEnterForeground() {
        if continueScanInBackground && isScanning {
            // Restore full generic scanning in foreground
            centralManager?.stopScan()
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    #endif
    
    func startScanning() {
        requestLocationPermission()
        if !continueScanInBackground {
            continueScanInBackground = true
        }
        guard !isScanning else { return }
        isScanning = true
        startCleanupTimer()
        
        if centralManager?.state == .poweredOn {
            #if os(iOS)
            if UIApplication.shared.applicationState == .background {
                let backgroundServices = [
                    CBUUID(string: "180F"), // Battery Service
                    CBUUID(string: "180A"), // Device Information
                    CBUUID(string: "FEAA")  // Eddystone
                ]
                centralManager?.scanForPeripherals(withServices: backgroundServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                return
            }
            #endif
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func stopScanning() {
        if continueScanInBackground {
            continueScanInBackground = false
        }
        guard isScanning else { return }
        isScanning = false
        stopCleanupTimer()
        centralManager?.stopScan()
        DispatchQueue.main.async {
            self.detectedDevices = []
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    #if os(iOS)
    @objc private func handleBackgroundRefreshStatusChange() {
        DispatchQueue.main.async {
            self.backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        }
    }
    #endif
    
    private func checkAndTriggerAlert(for device: BluetoothDevice) {
        // Limit alerts: only alert if RSSI exceeds threshold and not notified recently (cooldown)
        guard alertOnNewDevices else { return }
        guard device.rssi >= rssiThreshold else { return }
        
        let now = Date()
        let cooldownSeconds = notificationCooldown / 1000.0
        if let lastNotified = lastNotifiedTimes[device.deviceId], now.timeIntervalSince(lastNotified) < cooldownSeconds {
            return // Alert rate limit
        }
        
        lastNotifiedTimes[device.deviceId] = now
        sendPrivacyAlert(for: device)
        saveToSwiftDataHistory(device: device)
        
        DispatchQueue.main.async {
            self.activeNotification = device
        }
    }
    
    private func sendPrivacyAlert(for device: BluetoothDevice) {
        let lang = UserDefaults.standard.string(forKey: "selectedLanguage") ?? Bundle.main.preferredLocalizations.first ?? "en"
        let locale = Locale(identifier: lang)
        
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Smart Glasses Nearby! ⚠️", locale: locale)
        
        let distanceStr = String(format: "%.1f", device.estimatedDistance)
        let baseMsg = String(localized: "A \(device.name) has been detected approximately \(distanceStr) meters away.", locale: locale)
        
        var suffix = ""
        switch device.type {
        case "rayban_meta":
            suffix = " " + String(localized: "Be aware: this device can capture high-res video and audio discrete recording.", locale: locale)
        case "vision_pro":
            suffix = " " + String(localized: "Be aware: Spatial recording and cameras might be active.", locale: locale)
        case "snap_spectacles":
            suffix = " " + String(localized: "Be aware: AR filming and micro-cameras are active.", locale: locale)
        default:
            suffix = " " + String(localized: "Monitor your surroundings for privacy risks.", locale: locale)
        }
        
        content.body = baseMsg + suffix
        content.sound = .default
        
        #if os(iOS)
        if let image = UIImage(named: "notification_icon"),
           let data = image.pngData() {
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("notification_icon.png")
            try? data.write(to: tempURL)
            if let attachment = try? UNNotificationAttachment(identifier: "notification_icon", url: tempURL, options: nil) {
                content.attachments = [attachment]
            }
        }
        #endif
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error posting alert notification: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveToSwiftDataHistory(device: BluetoothDevice) {
        NotificationCenter.default.post(name: NSNotification.Name("NewDeviceDetectedHistory"), object: device)
    }
    
    // MARK: - Active Device Cleanup (Radar Calming)
    
    func startCleanupTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupTimer?.invalidate()
            self?.cleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.cleanupExpiredDevices()
            }
        }
    }
    
    func stopCleanupTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupTimer?.invalidate()
            self?.cleanupTimer = nil
        }
    }
    
    private func cleanupExpiredDevices() {
        let now = Date()
        let cooldownSeconds = notificationCooldown / 1000.0
        let filtered = detectedDevices.filter { now.timeIntervalSince($0.lastSeen) <= cooldownSeconds }
        if filtered.count != detectedDevices.count {
            self.detectedDevices = filtered
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if isScanning {
                #if os(iOS)
                if UIApplication.shared.applicationState == .background {
                    let backgroundServices = [
                        CBUUID(string: "180F"), // Battery Service
                        CBUUID(string: "180A"), // Device Information
                        CBUUID(string: "FEAA")  // Eddystone
                    ]
                    centralManager?.scanForPeripherals(withServices: backgroundServices, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                    return
                }
                #endif
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        } else {
            isScanning = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        guard !ignoredDevices.keys.contains(deviceId) else { return }
        
        // Filter and categorize device
        let name = peripheral.name ?? "Unknown Device"
        var detectedType = "unknown"
        
        let lowerName = name.lowercased()
        
        // Extract company ID from Manufacturer Specific Data
        var discoveredCompanyID: UInt16? = nil
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, manufacturerData.count >= 2 {
            discoveredCompanyID = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
        }
        
        // Categorize by Name or Company ID
        if lowerName.contains("ray-ban") || lowerName.contains("meta") || lowerName.contains("rb-meta") ||
           discoveredCompanyID == 0x058E || discoveredCompanyID == 0x01AB || discoveredCompanyID == 0x0D53 {
            detectedType = "rayban_meta"
        } else if (lowerName.contains("vision pro") || lowerName.contains("apple vision")) ||
                  ((lowerName.contains("vision") || lowerName.contains("glass")) && discoveredCompanyID == 0x004C) {
            detectedType = "vision_pro"
        } else if lowerName.contains("spectacles") || lowerName.contains("snapchat") ||
                  discoveredCompanyID == 0x03C2 {
            detectedType = "snap_spectacles"
        } else {
            // Filter out general Bluetooth devices (keyboards, headphones)
            let genericServices = [
                "keyboard", "mouse", "headphones", "airpods", "beats", "watch", "tv", "speaker", "tile", "trackpad"
            ]
            if genericServices.contains(where: { lowerName.contains($0) }) {
                return // Filter out standard accessories
            }
            detectedType = "unknown"
        }
        
        // Check if type is enabled in Settings
        guard enabledAlertTypes.contains(detectedType) else { return }
        
        let bluetoothDevice = BluetoothDevice(
            deviceId: deviceId,
            name: name,
            type: detectedType,
            rssi: RSSI.intValue,
            lastSeen: Date(),
            isSimulated: false
        )
        
        var updatedDevices = detectedDevices
        if let index = updatedDevices.firstIndex(where: { $0.deviceId == deviceId }) {
            var dev = updatedDevices[index]
            dev.rssi = RSSI.intValue
            dev.lastSeen = Date()
            updatedDevices[index] = dev
            
            checkAndTriggerAlert(for: dev)
        } else {
            updatedDevices.append(bluetoothDevice)
            checkAndTriggerAlert(for: bluetoothDevice)
        }
        
        DispatchQueue.main.async {
            self.detectedDevices = updatedDevices
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension BluetoothManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Play sound and badge in foreground, but do NOT show system banner 
        // because we present our custom branded in-app toast banner instead!
        completionHandler([.sound, .badge])
    }
}
