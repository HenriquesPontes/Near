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
        return Nearbyglasses.estimatedDistance(for: rssi)
    }
}

class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()

    @Published var detectedDevices: [BluetoothDevice] = []
    @Published var isScanning: Bool = false

    @AppStorage("alertOnNewDevices") var alertOnNewDevices: Bool = true
    @AppStorage("rssiThreshold") var rssiThreshold: Int = -75
    @AppStorage("autoStartScanning") var autoStartScanning: Bool = false
    @AppStorage("continueScanInBackground") var continueScanInBackground: Bool = false {
        willSet { objectWillChange.send() }
        didSet {
            if continueScanInBackground {
                if !isScanning { startScanning() }
            } else {
                if isScanning { stopScanning() }
            }
        }
    }
    @AppStorage("appAppearance") var appAppearance: String = "system"
    @AppStorage("notificationCooldown") var notificationCooldown: Double = 300000.0 {
        willSet { objectWillChange.send() }
    }

    var enabledAlertTypes: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: "enabledAlertTypes") ?? ""
            if raw.isEmpty { return [] }
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
    private var cleanupTimer: Timer?
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
        NotificationManager.shared.requestNotificationPermission()

        if autoStartScanning || continueScanInBackground {
            isScanning = true
            startCleanupTimer()
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    func startScanning() {
        guard !isScanning else { return }
        isScanning = true
        startCleanupTimer()
        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    func stopScanning() {
        guard isScanning else { return }
        isScanning = false
        stopCleanupTimer()
        centralManager?.stopScan()
        DispatchQueue.main.async {
            self.detectedDevices = []
        }
    }

    private func checkAndTriggerAlert(for device: BluetoothDevice) {
        guard alertOnNewDevices else { return }
        guard device.rssi >= rssiThreshold else { return }
        guard enabledAlertTypes.isEmpty || enabledAlertTypes.contains(device.type) else { return }

        let now = Date()
        let cooldownSeconds = notificationCooldown / 1000.0
        if let lastNotified = lastNotifiedTimes[device.deviceId],
           now.timeIntervalSince(lastNotified) < cooldownSeconds {
            return
        }

        lastNotifiedTimes[device.deviceId] = now
        
        let isNew = !self.detectedDevices.contains(where: { $0.deviceId == device.deviceId })
        let deviceCount = self.detectedDevices.count + (isNew ? 1 : 0)
        
        NotificationManager.shared.sendDeviceDetectedNotification(device: device, deviceCount: deviceCount)
        saveToSwiftDataHistory(device: device)
    }

    private func saveToSwiftDataHistory(device: BluetoothDevice) {
        NotificationCenter.default.post(name: NSNotification.Name("NewDeviceDetectedHistory"), object: device)
    }

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
        let expirationSeconds: TimeInterval = 60.0
        let filtered = detectedDevices.filter { now.timeIntervalSince($0.lastSeen) <= expirationSeconds }
        if filtered.count != detectedDevices.count {
            self.detectedDevices = filtered
        }
    }

    // Developer tool to test notifications
    func simulateAllNotifications() {
        let device = BluetoothDevice(
            deviceId: UUID().uuidString,
            name: "Simulated BLE Device",
            type: "unknown",
            rssi: -50,
            lastSeen: Date(),
            isSimulated: true
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let isNew = !self.detectedDevices.contains(where: { $0.deviceId == device.deviceId })
            let deviceCount = self.detectedDevices.count + (isNew ? 1 : 0)
            NotificationManager.shared.sendDeviceDetectedNotification(device: device, deviceCount: deviceCount)
            if !self.detectedDevices.contains(where: { $0.deviceId == device.deviceId }) {
                self.detectedDevices.append(device)
            }
            self.saveToSwiftDataHistory(device: device)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if isScanning {
                centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            }
        } else {
            isScanning = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let deviceId = peripheral.identifier.uuidString
        guard !ignoredDevices.keys.contains(deviceId) else { return }

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

        var deviceName = name
        if deviceName == "Unknown Device" || deviceName.isEmpty {
            if let manufacturer = manufacturerName {
                deviceName = "\(manufacturer) Device"
            }
        }

        var deviceType = "unknown"
        let lowerName = name.lowercased()
        let lowerMfg = manufacturerName?.lowercased() ?? ""
        
        if lowerName.contains("ray-ban") || lowerName.contains("rayban") || lowerName.contains("meta") || lowerMfg.contains("meta") {
            deviceType = "rayban_meta"
        } else if lowerName.contains("vision pro") || lowerName.contains("visionpro") || lowerName.contains("apple") || lowerMfg.contains("apple") {
            deviceType = "vision_pro"
        } else if lowerName.contains("spectacles") || lowerName.contains("snap") || lowerMfg.contains("snap") {
            deviceType = "snap_spectacles"
        } else if lowerName.contains("google") || lowerMfg.contains("google") {
            deviceType = "google_glass"
        } else if lowerName.contains("samsung") || lowerMfg.contains("samsung") {
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

        var updatedDevices = detectedDevices
        if let index = updatedDevices.firstIndex(where: { $0.deviceId == deviceId }) {
            var dev = updatedDevices[index]
            dev.rssi = RSSI.intValue
            dev.lastSeen = Date()
            if dev.manufacturer == nil { dev.manufacturer = manufacturerName }
            if dev.companyID == nil && discoveredCompanyID != nil { dev.companyID = Int(discoveredCompanyID!) }
            if dev.name == "Unknown Device" || dev.name.isEmpty { dev.name = deviceName }
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
