//
//  BluetoothManager.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import Combine
import CoreBluetooth
import Foundation
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

struct BluetoothDevice: Identifiable, Hashable {
    var id: UUID = UUID()
    var deviceId: String
    var name: String
    var type: String = "unknown"
    var rssi: Int
    var lastSeen: Date = Date()
    var isStarred: Bool = false
    var isSimulated: Bool = false
    var companyID: Int? = nil
    var manufacturer: String? = nil

    var threatLevel: String {
        if type == "unknown" && manufacturer == nil {
            return "Medium"
        } else {
            return "Low"
        }
    }

    var estimatedDistance: Double {
        return Near.estimatedDistance(for: rssi)
    }
}

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()

    @Published fileprivate(set) var detectedDevices: [BluetoothDevice] = [] {
        didSet {
            updateWidgetData()
        }
    }
    @Published fileprivate(set) var isScanning: Bool = false {
        didSet {
            updateWidgetData()
        }
    }

    private func updateWidgetData() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.luvlu.Near") {
            sharedDefaults.set(isScanning, forKey: "isScanning")
            sharedDefaults.set(detectedDevices.count, forKey: "detectedCount")
            sharedDefaults.synchronize()
        }
        WidgetCenter.shared.reloadAllTimelines()
        
        if isScanning {
            LiveActivityManager.shared.updateActivity(isScanning: isScanning, detectedDevices: detectedDevices)
        } else {
            LiveActivityManager.shared.endActivity()
        }
    }

    @objc func syncFromWidget() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.luvlu.Near") {
            let widgetScanning = sharedDefaults.bool(forKey: "isScanning")
            if widgetScanning != isScanning {
                if widgetScanning {
                    startScanning()
                } else {
                    stopScanning()
                }
            }
        }
    }

    @AppStorage("alertOnNewDevices") var alertOnNewDevices: Bool = true
    @AppStorage("enableAppBadge") var enableAppBadge: Bool = false {
        willSet { objectWillChange.send() }
        didSet {
            if !enableAppBadge {
                UNUserNotificationCenter.current().setBadgeCount(0)
            }
        }
    }
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("rssiThreshold") var rssiThreshold: Int = -75
    @AppStorage("autoStartScanning") var autoStartScanning: Bool = false
    @AppStorage("continueScanInBackground") var continueScanInBackground: Bool = false {
        willSet { objectWillChange.send() }
        didSet {
            if continueScanInBackground {
                if isScanning {
                    DispatchQueue.main.async { [weak self] in
                        self?.scanTimeoutTimer?.invalidate()
                        self?.scanTimeoutTimer = nil
                    }
                } else {
                    startScanning()
                }
            } else {
                if isScanning { stopScanning() }
            }
        }
    }
    @AppStorage("appAppearance") var appAppearance: String = "system"
    @AppStorage("notificationCooldown") var notificationCooldown: Double = 300000.0 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("isNotificationCooldownEnabled") var isNotificationCooldownEnabled: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("scanTimeout") var scanTimeout: Double = 60.0
    @AppStorage("isDeveloperModeEnabled") var isDeveloperModeEnabled: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("isSimulationEnabled") var isSimulationEnabled: Bool = false {
        willSet { objectWillChange.send() }
    }

    var enabledAlertTypes: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: "enabledAlertTypes") ?? ""
            if raw.isEmpty { 
                return ["rayban_meta", "oakley_meta", "oakley_meta_vanguard", "project_aria", "meta_orion", "meta_rayban_display", "other_meta_glasses"] 
            }
            let arr = (try? JSONDecoder().decode([String].self, from: Data(raw.utf8))) ?? []
            return Set(arr)
        }
        set {
            if let data = try? JSONEncoder().encode(Array(newValue)),
               let str = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(str, forKey: "enabledAlertTypes")
            }
            objectWillChange.send()
        }
    }

    var ignoredDevices: [String: String] {
        get {
            let raw = UserDefaults.standard.string(forKey: "ignoredDevices") ?? ""
            if raw.isEmpty { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: Data(raw.utf8))) ?? [:]
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                UserDefaults.standard.set(str, forKey: "ignoredDevices")
            }
            objectWillChange.send()
        }
    }

    func ignoreDevice(id: String, name: String) {
        var currentIgnored = ignoredDevices
        currentIgnored[id] = name
        ignoredDevices = currentIgnored
        
        internalDevices.removeValue(forKey: id)
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
    private var lastNotifiedTimes: [String: Date] = [:]
    private var lastGlobalNotificationTime: Date? = nil
    private var updateTimer: Timer?
    private var scanTimeoutTimer: Timer?
    private var internalDevices: [String: BluetoothDevice] = [:]
    private var companyIdentifiers: [String: String] = [:]

    private func loadCompanyIdentifiers() {
        guard let url = Bundle.main.url(forResource: "company_identifiers", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            companyIdentifiers = try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("Failed to decode company_identifiers.json: \(error)")
        }
    }

    func companyName(for companyID: UInt16) -> String? {
        let hexStr = String(format: "0x%04X", companyID)
        return companyIdentifiers[hexStr]
    }

    override init() {
        super.init()
        loadCompanyIdentifiers()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(syncFromWidget),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // Perform initial sync from widget state
        syncFromWidget()

        if autoStartScanning || continueScanInBackground {
            isScanning = true
            startUpdateTimer()
        }
    }

    deinit {
        updateTimer?.invalidate()
    }

    func clearDetectedDevices() {
        DispatchQueue.main.async {
            self.internalDevices.removeAll()
            self.detectedDevices = []
        }
    }

    func startScanning() {
        guard !isScanning else { return }
        
        // Clear previous results when starting a new scan
        DispatchQueue.main.async {
            self.internalDevices.removeAll()
            self.detectedDevices = []
            
            #if targetEnvironment(simulator)
            if self.isDeveloperModeEnabled && self.isSimulationEnabled {
                let mockTemplates = [
                    ("sim_rayban_meta", "Ray-Ban Meta", "rayban_meta", "Ray-Ban"),
                    ("sim_vision_pro", "Apple Vision Pro", "vision_pro", "Apple")
                ]
                let now = Date()
                for template in mockTemplates {
                    let device = BluetoothDevice(
                        deviceId: template.0,
                        name: template.1,
                        type: template.2,
                        rssi: Int.random(in: -65 ... -45),
                        lastSeen: now,
                        isSimulated: true,
                        manufacturer: template.3
                    )
                    self.internalDevices[template.0] = device
                }
                self.updateUIAndCleanup()
            }
            #endif
        }
        
        isScanning = true
        startUpdateTimer()
        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.scanTimeoutTimer?.invalidate()
            
            // Only set a timeout if we are NOT in continuous background radar scanning mode
            if let self = self, !self.continueScanInBackground {
                let timeout = self.scanTimeout
                if timeout > 0 {
                    self.scanTimeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
                        self?.stopScanning()
                    }
                }
            }
        }
    }

    func stopScanning() {
        guard isScanning else { return }
        isScanning = false
        stopUpdateTimer()
        scanTimeoutTimer?.invalidate()
        scanTimeoutTimer = nil
        centralManager?.stopScan()
    }

    private func checkAndTriggerAlert(for device: BluetoothDevice, isNew: Bool) {
        guard hasSeenOnboarding else { return }
        guard alertOnNewDevices else { return }
        guard device.rssi >= rssiThreshold else { return }
        guard enabledAlertTypes.contains(device.type) else { return }

        let now = Date()
        let cooldownSeconds = notificationCooldown / 1000.0
        
        if isNotificationCooldownEnabled {
            // 1. Per-device cooldown
            if let lastNotified = lastNotifiedTimes[device.deviceId],
               now.timeIntervalSince(lastNotified) < cooldownSeconds {
                return
            }
            
            // 2. Global cooldown (60 seconds) to prevent notification spam from many devices at once.
            // We bypass the global cooldown for High threat devices.
            if device.threatLevel != "High" {
                if let lastGlobal = lastGlobalNotificationTime,
                   now.timeIntervalSince(lastGlobal) < 60.0 {
                    return
                }
            }
        }

        lastNotifiedTimes[device.deviceId] = now
        lastGlobalNotificationTime = now
        
        let deviceCount = self.internalDevices.count
        
        NotificationManager.shared.sendDeviceDetectedNotification(device: device, deviceCount: deviceCount)
        saveToSwiftDataHistory(device: device)
    }

    private func saveToSwiftDataHistory(device: BluetoothDevice) {
        NotificationCenter.default.post(name: NSNotification.Name("NewDeviceDetectedHistory"), object: device)
    }

    func startUpdateTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.updateTimer?.invalidate()
            self?.updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                self?.updateUIAndCleanup()
            }
        }
    }

    func stopUpdateTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.updateTimer?.invalidate()
            self?.updateTimer = nil
        }
    }

    private func updateUIAndCleanup() {
        let now = Date()
        let expirationSeconds: TimeInterval = 60.0
        
        #if targetEnvironment(simulator)
        if isScanning && isDeveloperModeEnabled && isSimulationEnabled {
            let mockTemplates = [
                ("sim_rayban_meta", "Ray-Ban Meta", "rayban_meta", "Ray-Ban"),
                ("sim_vision_pro", "Apple Vision Pro", "vision_pro", "Apple"),
                ("sim_snap_spec", "Spectacles 4", "snap_spectacles", "Snap"),
                ("sim_oakley_meta", "Oakley Meta Vanguard", "oakley_meta_vanguard", "Oakley"),
                ("sim_google_glass", "Google Glass Enterprise", "google_glass", "Google")
            ]
            
            // Randomly update or add one of the mock devices to simulate realistic movement/detection
            if Int.random(in: 0...3) == 0 {
                let template = mockTemplates.randomElement()!
                let currentRssi = internalDevices[template.0]?.rssi ?? Int.random(in: -70 ... -40)
                let change = Int.random(in: -4 ... 4)
                let newRssi = max(-95, min(-35, currentRssi + change))
                
                let isNew = internalDevices[template.0] == nil
                let device = BluetoothDevice(
                    deviceId: template.0,
                    name: template.1,
                    type: template.2,
                    rssi: newRssi,
                    lastSeen: now,
                    isSimulated: true,
                    manufacturer: template.3
                )
                
                internalDevices[template.0] = device
                if isNew {
                    checkAndTriggerAlert(for: device, isNew: true)
                }
            }
        }
        #endif
        
        // Remove expired devices
        let keysToRemove = internalDevices.filter { now.timeIntervalSince($0.value.lastSeen) > expirationSeconds }.map { $0.key }
        for key in keysToRemove {
            internalDevices.removeValue(forKey: key)
        }
        
        // Convert to array and update UI
        let updatedArray = Array(internalDevices.values)
            .filter { enabledAlertTypes.contains($0.type) }
            .sorted(by: { $0.rssi > $1.rssi })
        self.detectedDevices = updatedArray
    }

    func simulateAllNotifications() {
        guard isDeveloperModeEnabled && isSimulationEnabled else { return }
        let mockDevices = [
            BluetoothDevice(deviceId: "sim_rayban_meta", name: "Ray-Ban Meta", type: "rayban_meta", rssi: -45, lastSeen: Date(), isSimulated: true, manufacturer: "Ray-Ban"),
            BluetoothDevice(deviceId: "sim_vision_pro", name: "Apple Vision Pro", type: "vision_pro", rssi: -55, lastSeen: Date(), isSimulated: true, manufacturer: "Apple"),
            BluetoothDevice(deviceId: "sim_snap_spec", name: "Spectacles 4", type: "snap_spectacles", rssi: -62, lastSeen: Date(), isSimulated: true, manufacturer: "Snap"),
            BluetoothDevice(deviceId: "sim_oakley_meta", name: "Oakley Meta Vanguard", type: "oakley_meta_vanguard", rssi: -50, lastSeen: Date(), isSimulated: true, manufacturer: "Oakley"),
            BluetoothDevice(deviceId: "sim_google_glass", name: "Google Glass Enterprise", type: "google_glass", rssi: -68, lastSeen: Date(), isSimulated: true, manufacturer: "Google")
        ]
        
        for (index, device) in mockDevices.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.5) { [weak self] in
                guard let self = self else { return }
                self.internalDevices[device.deviceId] = device
                let deviceCount = self.internalDevices.count
                NotificationManager.shared.sendDeviceDetectedNotification(device: device, deviceCount: deviceCount)
                self.saveToSwiftDataHistory(device: device)
                self.updateUIAndCleanup()
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        #if targetEnvironment(simulator)
        // On simulator, ignore hardware checks so simulation can run only if developer mode and simulation are enabled
        if isDeveloperModeEnabled && isSimulationEnabled {
            if central.state == .poweredOn && isScanning {
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        } else {
            isScanning = false
        }
        #else
        if central.state == .poweredOn {
            if isScanning {
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        } else {
            isScanning = false
        }
        #endif
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        guard !ignoredDevices.keys.contains(deviceId) else { return }
        if TrustedDeviceManager.shared.isTrusted(id: deviceId) { return }

        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? "Unknown Device"

        var discoveredCompanyID: UInt16? = nil
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, manufacturerData.count >= 2 {
            discoveredCompanyID = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
        }

        var manufacturerName: String? = nil
        if let companyID = discoveredCompanyID {
            manufacturerName = companyName(for: companyID)
        }

        // 1. Resolve Device Type
        var deviceType = "unknown"
        let lowerName = name.lowercased()
        let lowerMfg = manufacturerName?.lowercased() ?? ""
        
        let isTVOrSpeaker = lowerName.contains("tv") || lowerName.contains("television") || lowerName.contains("soundbar") || lowerName.contains("speaker") || lowerName.contains("receiver") || lowerName.contains("monitor")
        let isPhoneOrTabletOrPC = lowerName.contains("phone") || lowerName.contains("galaxy") || lowerName.contains("sm-") || lowerName.contains("pixel") || lowerName.contains("nest") || lowerName.contains("hub") || lowerName.contains("laptop") || lowerName.contains("computer")
        let isSmartWatch = lowerName.contains("watch") || lowerName.contains("fitbit") || lowerName.contains("gear") || lowerName.contains("active") || lowerName.contains("band")
        let isNonGlassesDevice = isTVOrSpeaker || isPhoneOrTabletOrPC || isSmartWatch
        
        if lowerName.contains("oakley") && (lowerName.contains("meta") || lowerMfg.contains("meta")) {
            if lowerName.contains("vanguard") {
                deviceType = "oakley_meta_vanguard"
            } else {
                deviceType = "oakley_meta"
            }
        } else if (lowerName.contains("ray-ban") || lowerName.contains("rayban")) && lowerName.contains("display") {
            deviceType = "meta_rayban_display"
        } else if lowerName.contains("ray-ban") || lowerName.contains("rayban") || (lowerName.contains("meta") && lowerName.contains("ray")) {
            deviceType = "rayban_meta"
        } else if lowerName.contains("aria") && (lowerName.contains("project") || lowerName.contains("meta") || lowerMfg.contains("meta")) {
            deviceType = "project_aria"
        } else if lowerName.contains("orion") && (lowerName.contains("meta") || lowerMfg.contains("meta")) {
            deviceType = "meta_orion"
        } else if lowerName.contains("meta") || lowerMfg.contains("meta") {
            deviceType = "other_meta_glasses"
        } else if lowerName.contains("vision pro") || lowerName.contains("visionpro") || lowerName.contains("apple") || lowerMfg.contains("apple") || lowerName.contains("macbook") || lowerName.contains("iphone") || lowerName.contains("ipad") || lowerName.contains("airpods") || lowerName.contains("airtag") || lowerName.contains("imac") || lowerName.contains("mac mini") {
            deviceType = "vision_pro"
        } else if lowerName.contains("spectacles") || lowerName.contains("snap") || lowerMfg.contains("snap") {
            deviceType = "snap_spectacles"
        } else if (lowerName.contains("google") || lowerMfg.contains("google")) && (lowerName.contains("glass") || lowerName.contains("eyewear") || lowerName.contains("spectacles")) && !isNonGlassesDevice {
            deviceType = "google_glass"
        } else if (lowerName.contains("samsung") || lowerMfg.contains("samsung")) && (lowerName.contains("glasses") || lowerName.contains("glass") || lowerName.contains("eyewear") || lowerName.contains("xr") || lowerName.contains("gear vr") || lowerName.contains("gearvr")) && !isNonGlassesDevice {
            deviceType = "samsung_glasses"
        } else if lowerName.contains("xreal") || lowerName.contains("nreal") || lowerMfg.contains("xreal") {
            deviceType = "google_xreal"
        } else if lowerName.contains("brilliant") || lowerName.contains("frame") || lowerMfg.contains("brilliant") {
            deviceType = "brilliant_labs"
        } else if lowerName.contains("oho") || lowerMfg.contains("oho") {
            deviceType = "oho_sunshine"
        } else if lowerName.contains("ivue") || lowerMfg.contains("ivue") {
            deviceType = "ivue_glasses"
        }

        // 2. Resolve Manufacturer Fallback if nil
        if manufacturerName == nil {
            switch deviceType {
            case "vision_pro":
                manufacturerName = "Apple"
            case "rayban_meta", "meta_rayban_display":
                manufacturerName = "Ray-Ban"
            case "oakley_meta", "oakley_meta_vanguard":
                manufacturerName = "Oakley"
            case "project_aria", "meta_orion", "other_meta_glasses":
                manufacturerName = "Meta"
            case "snap_spectacles":
                manufacturerName = "Snap"
            case "google_glass":
                manufacturerName = "Google"
            case "samsung_glasses":
                manufacturerName = "Samsung"
            case "google_xreal":
                manufacturerName = "Xreal"
            case "brilliant_labs":
                manufacturerName = "Brilliant Labs"
            case "oho_sunshine":
                manufacturerName = "OhO"
            case "ivue_glasses":
                manufacturerName = "iVUE"
            default:
                break
            }
        }

        // 3. Resolve Device Name using Resolved Manufacturer
        var deviceName = name
        if deviceName == "Unknown Device" || deviceName.isEmpty {
            if let manufacturer = manufacturerName {
                deviceName = "\(manufacturer) Device"
            }
        }

        let bluetoothDevice = BluetoothDevice(
            deviceId: deviceId,
            name: deviceName,
            type: deviceType,
            rssi: RSSI.intValue,
            lastSeen: Date(),
            isSimulated: false,
            companyID: discoveredCompanyID != nil ? Int(discoveredCompanyID!) : nil,
            manufacturer: manufacturerName
        )

        let isNew = internalDevices[deviceId] == nil
        var dev = internalDevices[deviceId] ?? bluetoothDevice
        dev.rssi = RSSI.intValue
        dev.lastSeen = Date()
        if dev.manufacturer == nil { dev.manufacturer = manufacturerName }
        if dev.companyID == nil && discoveredCompanyID != nil { dev.companyID = Int(discoveredCompanyID!) }
        if dev.name == "Unknown Device" || dev.name.isEmpty { dev.name = deviceName }
        
        internalDevices[deviceId] = dev
        checkAndTriggerAlert(for: dev, isNew: isNew)
    }
}

class MockBluetoothManager: BluetoothManager {
    private var mockTimer: Timer?

    override func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        
        // Populate mock devices immediately
        clearDetectedDevices()
        self.detectedDevices = [
            BluetoothDevice(deviceId: "mock_rayban", name: "Ray-Ban Meta", type: "rayban_meta", rssi: -55, isSimulated: true),
            BluetoothDevice(deviceId: "mock_tracker", name: "Tile Tracker", type: "unknown", rssi: -72, isSimulated: true)
        ]
        
        // Periodically simulate RSSI variations to verify UI pulse/radar animations
        mockTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            var updated = self.detectedDevices
            for i in 0..<updated.count {
                let randomDelta = Int.random(in: -5...5)
                updated[i].rssi = max(-95, min(-40, updated[i].rssi + randomDelta))
                updated[i].lastSeen = Date()
            }
            self.detectedDevices = updated
        }
    }

    override func stopScanning() {
        guard isScanning else { return }
        isScanning = false
        mockTimer?.invalidate()
        mockTimer = nil
    }

    override func clearDetectedDevices() {
        self.detectedDevices = []
    }
}
