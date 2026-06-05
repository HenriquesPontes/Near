//
//  BluetoothManager.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import Combine
import CoreBluetooth
internal import CoreLocation
import Foundation
import SwiftUI
import UIKit
import UserNotifications

struct BluetoothDevice: Identifiable, Hashable {
    var id: UUID = UUID()
    var deviceId: String
    var name: String
    var type: String  // "rayban_meta", "vision_pro", "snap_spectacles", "google_glass", "samsung_glasses", "unknown"
    var rssi: Int
    var lastSeen: Date = Date()
    var isStarred: Bool = false
    var isSimulated: Bool = false
    var companyID: Int? = nil
    var manufacturer: String? = nil

    var threatLevel: String {
        switch type {
        case "rayban_meta", "oakley_meta", "project_aria", "meta_orion", "other_meta_glasses",
            "vision_pro", "google_glass", "google_gentle_monster", "google_warby_parker",
            "google_xreal", "samsung_glasses":
            return "High"
        case "snap_spectacles":
            return "High"
        default:
            return "Medium"
        }
    }

    var estimatedDistance: Double {
        return Nearbyglasses.estimatedDistance(for: rssi)
    }
}

class BluetoothManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = BluetoothManager()

    @Published var detectedDevices: [BluetoothDevice] = []
    @Published var isScanning: Bool = false

    // Persisted settings via UserDefaults
    @AppStorage("alertOnNewDevices") var alertOnNewDevices: Bool = true
    @AppStorage("rssiThreshold") var rssiThreshold: Int = -75
    @AppStorage("autoStartScanning") var autoStartScanning: Bool = false
    @AppStorage("continueScanInBackground") var continueScanInBackground: Bool = false {
        willSet {
            objectWillChange.send()
        }
        didSet {
            if continueScanInBackground {
                if !isScanning {
                    startScanning()
                } else {
                    locationManager?.startUpdatingLocation()
                }
            } else {
                locationManager?.stopUpdatingLocation()
                if isScanning {
                    stopScanning()
                }
            }
        }
    }
    @AppStorage("appAppearance") var appAppearance: String = "system"
    @AppStorage("notificationCooldown") var notificationCooldown: Double = 300000.0 {
        willSet {
            objectWillChange.send()
        }
    }

    // enabledAlertTypes persisted as JSON string since @AppStorage doesn't support Set<String>
    var enabledAlertTypes: Set<String> {
        get {
            let raw = UserDefaults.standard.string(forKey: "enabledAlertTypes") ?? ""
            if raw.isEmpty {
                return [
                    "rayban_meta", "oakley_meta", "project_aria", "meta_orion",
                    "other_meta_glasses", "vision_pro", "snap_spectacles", "google_glass",
                    "google_gentle_monster", "google_warby_parker", "google_xreal",
                    "samsung_glasses", "oho_sunshine", "ivue_glasses", "brilliant_labs", "unknown",
                ]
            }
            let arr = (try? JSONDecoder().decode([String].self, from: Data(raw.utf8))) ?? []
            return Set(arr)
        }
        set {
            let arr = Array(newValue)
            if let data = try? JSONEncoder().encode(arr),
                let str = String(data: data, encoding: .utf8)
            {
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
            if let data = try? JSONEncoder().encode(newValue),
                let str = String(data: data, encoding: .utf8)
            {
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
    private var backgroundScanTimer: Timer?
    private var companyIdentifiers: [String: String] = [:]

    private func loadCompanyIdentifiers() {
        guard let url = Bundle.main.url(forResource: "company_identifiers", withExtension: "json")
        else {
            print("company_identifiers.json not found in Bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            companyIdentifiers = try JSONDecoder().decode([String: String].self, from: data)
            print("Successfully loaded \(companyIdentifiers.count) company identifiers")
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
        self.locationManager = CLLocationManager()
        self.locationManager?.delegate = self
        self.locationManager?.allowsBackgroundLocationUpdates = true
        self.locationManager?.showsBackgroundLocationIndicator = true
        self.locationManager?.pausesLocationUpdatesAutomatically = false
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        UNUserNotificationCenter.current().delegate = self
        requestNotificationPermission()
        requestLocationPermission()

        #if os(iOS)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification, object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification, object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(handleBackgroundRefreshStatusChange),
                name: UIApplication.backgroundRefreshStatusDidChangeNotification, object: nil)
            self.backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        #endif

        // Auto-start scanning on launch if scan toggle is enabled
        if continueScanInBackground {
            isScanning = true
            startCleanupTimer()
            // Ensure location manager starts on launch to keep background scanning alive
            locationManager?.startUpdatingLocation()
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    func requestLocationPermission() {
        guard let manager = locationManager else { return }
        let status = manager.authorizationStatus
        locationAuthorizationStatus = status
        if status == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationAuthorizationStatus = manager.authorizationStatus
    }

    func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        locationAuthorizationStatus = status
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Required to receive location updates and keep the app fully awake in the background.
        // We don't need to do anything with the locations.
    }

    #if os(iOS)
        @objc private func handleDidEnterBackground() {
            if continueScanInBackground && isScanning {
                // Location updates are already running, which keeps the app executing in the background.

                // Restart scan with explicit services to allow iOS background scanning to work
                centralManager?.stopScan()
                let backgroundServices = [
                    CBUUID(string: "FD60"),  // Meta
                    CBUUID(string: "180F"),  // Battery Service
                    CBUUID(string: "180A"),  // Device Information
                    CBUUID(string: "FEAA"),  // Eddystone
                ]
                centralManager?.scanForPeripherals(
                    withServices: backgroundServices,
                    options: nil)  // Note: AllowDuplicatesKey is IGNORED in the background by iOS.

                // Start a timer to periodically restart the scan. This bypasses the CoreBluetooth
                // limitation where duplicates are ignored in the background, allowing us to get
                // updated RSSI values and trigger notifications when devices get closer.
                startBackgroundScanRestarter()
            }
        }

        @objc private func handleWillEnterForeground() {
            if continueScanInBackground && isScanning {
                stopBackgroundScanRestarter()

                // Restore full generic scanning in foreground
                centralManager?.stopScan()
                centralManager?.scanForPeripherals(
                    withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
                )
            }
        }

        private func startBackgroundScanRestarter() {
            backgroundScanTimer?.invalidate()
            // Restart scan every 10 seconds to fetch new RSSI values
            backgroundScanTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) {
                [weak self] _ in
                guard let self = self, self.isScanning, self.continueScanInBackground else {
                    return
                }

                self.centralManager?.stopScan()
                let backgroundServices = [
                    CBUUID(string: "FD60"),
                    CBUUID(string: "180F"),
                    CBUUID(string: "180A"),
                    CBUUID(string: "FEAA"),
                ]
                self.centralManager?.scanForPeripherals(
                    withServices: backgroundServices,
                    options: nil)
            }
        }

        private func stopBackgroundScanRestarter() {
            backgroundScanTimer?.invalidate()
            backgroundScanTimer = nil
        }
    #endif

    func startScanning() {
        requestLocationPermission()
        guard !isScanning else { return }
        isScanning = true
        startCleanupTimer()

        if continueScanInBackground {
            // Start location tracking to keep the background scanning alive
            locationManager?.startUpdatingLocation()
        }

        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(
                withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }

    func stopScanning() {
        guard isScanning else { return }
        isScanning = false
        stopCleanupTimer()
        #if os(iOS)
            stopBackgroundScanRestarter()
        #endif
        centralManager?.stopScan()
        locationManager?.stopUpdatingLocation()
        DispatchQueue.main.async {
            self.detectedDevices = []
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
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
        if let lastNotified = lastNotifiedTimes[device.deviceId],
            now.timeIntervalSince(lastNotified) < cooldownSeconds
        {
            return  // Alert rate limit
        }

        lastNotifiedTimes[device.deviceId] = now
        sendPrivacyAlert(for: device)
        saveToSwiftDataHistory(device: device)
        AnalyticsManager.shared.trackDetection(device: device)
    }

    private func sendPrivacyAlert(for device: BluetoothDevice) {
        let lang =
            UserDefaults.standard.string(forKey: "selectedLanguage") ?? Bundle.main
            .preferredLocalizations.first ?? "en"
        let locale = Locale(identifier: lang)

        let content = UNMutableNotificationContent()

        // Dynamically select localized title based on device type or manufacturer
        let title: String
        switch device.type {
        case "rayban_meta", "oakley_meta", "project_aria", "meta_orion", "other_meta_glasses":
            title = String(localized: "Meta AI Glasses Nearby! ⚠️", locale: locale)
        case "vision_pro":
            title = String(localized: "Apple Smart Glasses Nearby! ⚠️", locale: locale)
        case "snap_spectacles":
            title = String(localized: "Snapchat Spectacles Nearby! ⚠️", locale: locale)
        case "google_glass", "google_gentle_monster", "google_warby_parker", "google_xreal":
            title = String(localized: "Google AI Glasses Nearby! ⚠️", locale: locale)
        case "samsung_glasses":
            title = String(localized: "Samsung Smartglasses Nearby! ⚠️", locale: locale)
        case "oho_sunshine":
            title = String(localized: "OhO Camera Glasses Nearby! ⚠️", locale: locale)
        case "ivue_glasses":
            title = String(localized: "iVue Camera Glasses Nearby! ⚠️", locale: locale)
        case "brilliant_labs":
            title = String(localized: "Brilliant Labs Glasses Nearby! ⚠️", locale: locale)
        default:
            if let manufacturer = device.manufacturer, !manufacturer.isEmpty {
                title = String(localized: "\(manufacturer) Device Nearby! ⚠️", locale: locale)
            } else {
                title = String(localized: "Unknown Device Nearby! ⚠️", locale: locale)
            }
        }
        content.title = title

        // Set dynamic localized subtitle as the device display name
        let displayName: String
        if device.name == "Unknown Device" {
            displayName = String(localized: "Unknown Device", locale: locale)
        } else {
            displayName = device.name
        }
        content.subtitle = displayName

        let distanceStr = String(format: "%.1f", device.estimatedDistance)
        let baseMsg = String(
            localized: "Detected approximately \(distanceStr) meters away.", locale: locale)

        var suffix = ""
        switch device.type {
        case "rayban_meta", "oakley_meta", "other_meta_glasses":
            suffix =
                " "
                + String(
                    localized:
                        "Be aware: this device can capture high-res video and audio discrete recording.",
                    locale: locale)
        case "project_aria":
            suffix =
                " "
                + String(
                    localized:
                        "Be aware: this research device captures extensive environmental and sensor data.",
                    locale: locale)
        case "meta_orion":
            suffix =
                " "
                + String(
                    localized:
                        "Be aware: AR holographic glasses with spatial tracking active.",
                    locale: locale)
        case "vision_pro":
            suffix =
                " "
                + String(
                    localized: "Be aware: Spatial recording and cameras might be active.",
                    locale: locale)
        case "snap_spectacles":
            suffix =
                " "
                + String(
                    localized: "Be aware: AR filming and micro-cameras are active.", locale: locale)
        case "google_glass", "google_gentle_monster", "google_warby_parker":
            suffix =
                " "
                + String(
                    localized: "Be aware: First-person AI assistant and camera may be active.",
                    locale: locale)
        case "google_xreal":
            suffix =
                " "
                + String(
                    localized: "Be aware: Display-equipped XR glasses with spatial tracking.",
                    locale: locale)
        case "samsung_glasses":
            suffix =
                " "
                + String(
                    localized: "Be aware: Smart eyewear with potential recording active.",
                    locale: locale)
        case "oho_sunshine", "ivue_glasses":
            suffix =
                " "
                + String(
                    localized: "Be aware: Wearable camera glasses designed for recording.",
                    locale: locale)
        case "brilliant_labs":
            suffix =
                " "
                + String(
                    localized: "Be aware: Multimodal AI-powered smart glasses active.",
                    locale: locale)
        default:
            suffix =
                " "
                + String(localized: "Monitor your surroundings for privacy risks.", locale: locale)
        }

        content.body = baseMsg + suffix
        content.sound = .default
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
        }

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
        NotificationCenter.default.post(
            name: NSNotification.Name("NewDeviceDetectedHistory"), object: device)
    }

    // MARK: - Active Device Cleanup (Radar Calming)

    func startCleanupTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupTimer?.invalidate()
            self?.cleanupTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) {
                [weak self] _ in
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
        // Devices should remain active for longer than the notification cooldown (e.g., 60 seconds)
        // because BLE advertisements might be sparse when connected.
        let expirationSeconds: TimeInterval = 60.0
        let filtered = detectedDevices.filter {
            now.timeIntervalSince($0.lastSeen) <= expirationSeconds
        }
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
                            CBUUID(string: "FD60"),  // Meta
                            CBUUID(string: "180F"),  // Battery Service
                            CBUUID(string: "180A"),  // Device Information
                            CBUUID(string: "FEAA"),  // Eddystone
                        ]
                        centralManager?.scanForPeripherals(
                            withServices: backgroundServices,
                            options: nil)
                        return
                    }
                #endif
                centralManager?.scanForPeripherals(
                    withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
                )
            }
        } else {
            isScanning = false
        }
    }

    func centralManager(
        _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber
    ) {
        let deviceId = peripheral.identifier.uuidString
        guard !ignoredDevices.keys.contains(deviceId) else { return }

        // Filter and categorize device
        let advName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = advName ?? peripheral.name ?? "Unknown Device"
        var detectedType = "unknown"

        let lowerName = name.lowercased()

        // Extract company ID from Manufacturer Specific Data
        var discoveredCompanyID: UInt16? = nil
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey]
            as? Data, manufacturerData.count >= 2
        {
            discoveredCompanyID = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
        }

        var hasMetaServiceUUID = false
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            hasMetaServiceUUID = serviceUUIDs.contains(CBUUID(string: "FD60"))
        }
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Any]
        {
            if serviceData.keys.contains(CBUUID(string: "FD60")) {
                hasMetaServiceUUID = true
            }
        }

        // Resolve manufacturer name from company ID
        var manufacturerName: String? = nil
        if let companyID = discoveredCompanyID {
            manufacturerName = companyName(for: companyID)
        }

        // 1. Categorize by Name or Company ID FIRST
        let isMetaCompany =
            hasMetaServiceUUID
            || (discoveredCompanyID == 0x058E || discoveredCompanyID == 0x01AB
                || discoveredCompanyID == 0x0D53)
        let isExplicitRayBan =
            lowerName.contains("ray-ban") || lowerName.contains("rb-meta")
            || lowerName.contains("rb meta")
            || lowerName.contains("rayban") || discoveredCompanyID == 0x01AB
        let isExplicitOakley = lowerName.contains("oakley")
        let isExplicitAria = lowerName.contains("aria")
        let isExplicitOrion = lowerName.contains("orion")
        let isMetaWithKeywords =
            lowerName.contains("meta")
            && (isMetaCompany || lowerName.contains("glasses") || lowerName.contains("smart"))

        if isExplicitRayBan {
            detectedType = "rayban_meta"
        } else if isExplicitOakley {
            detectedType = "oakley_meta"
        } else if isExplicitAria {
            detectedType = "project_aria"
        } else if isExplicitOrion {
            detectedType = "meta_orion"
        } else if isMetaCompany || isMetaWithKeywords {
            // Fallback for other Meta devices
            detectedType = "other_meta_glasses"
        } else if (lowerName.contains("vision pro") || lowerName.contains("apple vision"))
            || ((lowerName.contains("vision") || lowerName.contains("glass"))
                && discoveredCompanyID == 0x004C)
        {
            detectedType = "vision_pro"
        } else if lowerName.contains("spectacles")
            || (lowerName.contains("snapchat") && !lowerName.contains("pixy"))
            || discoveredCompanyID == 0x03C2
        {
            detectedType = "snap_spectacles"
        } else if lowerName.contains("google glass")
            || (lowerName.contains("glass")
                && (discoveredCompanyID == 0x018E || discoveredCompanyID == 0x00E0))
        {
            detectedType = "google_glass"
        } else if lowerName.contains("gentle monster")
            || (lowerName.contains("monster") && discoveredCompanyID == 0x00E0)
        {
            detectedType = "google_gentle_monster"
        } else if lowerName.contains("warby parker")
            || (lowerName.contains("warby") && discoveredCompanyID == 0x00E0)
        {
            detectedType = "google_warby_parker"
        } else if lowerName.contains("xreal") || lowerName.contains("project aura")
            || (lowerName.contains("aura") && discoveredCompanyID == 0x00E0)
        {
            detectedType = "google_xreal"
        } else if (lowerName.contains("samsung") && lowerName.contains("glass"))
            || (lowerName.contains("glass")
                && (discoveredCompanyID == 0x02DE || discoveredCompanyID == 0x0075))
        {
            detectedType = "samsung_glasses"
        } else if lowerName.contains("oho sunshine") {
            detectedType = "oho_sunshine"
        } else if lowerName.contains("ivue") {
            detectedType = "ivue_glasses"
        } else if lowerName.contains("brilliant")
            && (lowerName.contains("labs") || lowerName.contains("frame")
                || lowerName.contains("halo"))
        {
            detectedType = "brilliant_labs"
        } else {
            detectedType = "unknown"
        }

        // 2. Filter out general Bluetooth devices if we couldn't strongly identify it
        // We use a regular expression with word boundaries (\b) so short words like "tv" or "car"
        // don't accidentally match substrings in valid names (e.g. "SmartVision" containing "tv").
        if detectedType == "unknown" {
            let genericDevicesRegex =
                "\\b(keyboard|mouse|headphones|airpods|beats|watch|tv|speaker|tile|trackpad|iphone|ipad|macbook|mac mini|mac studio|imac|mac pro|pencil|homepod|appletv|quest|oculus|tracker|tag|smarttag|display|audio|nintendo|playstation|xbox|car|ford|toyota|honda|bmw|tesla)\\b"

            if lowerName.range(of: genericDevicesRegex, options: .regularExpression) != nil {
                return  // Filter out standard accessories and non-glasses devices
            }
        }

        // Check if type is enabled in Settings
        guard enabledAlertTypes.contains(detectedType) else { return }

        // Improve name if it is Unknown Device but we have a manufacturer or known type
        var deviceName = name
        if detectedType != "unknown" {
            deviceName = displayNameForType(detectedType)
        } else if deviceName == "Unknown Device" || deviceName.isEmpty {
            if let manufacturer = manufacturerName {
                deviceName = "\(manufacturer) Device"
            }
        }

        let bluetoothDevice = BluetoothDevice(
            deviceId: deviceId,
            name: deviceName,
            type: detectedType,
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
            if dev.manufacturer == nil {
                dev.manufacturer = manufacturerName
            }
            if dev.companyID == nil && discoveredCompanyID != nil {
                dev.companyID = Int(discoveredCompanyID!)
            }
            if dev.name == "Unknown Device" || dev.name.isEmpty {
                dev.name = deviceName
            }
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

    // Developer tool to test notifications
    func simulateAllNotifications() {
        let types = [
            ("rayban_meta", "Meta AI Glasses"),
            ("vision_pro", "Apple Vision Pro"),
            ("snap_spectacles", "Snapchat Spectacles Smartglasses"),
            ("google_glass", "Google Glass"),
            ("samsung_glasses", "Samsung Smartglasses"),
            ("oho_sunshine", "OhO Camera Glasses"),
            ("brilliant_labs", "Brilliant Labs Glasses"),
            ("unknown", "Unknown Device"),
        ]

        for (index, info) in types.enumerated() {
            let device = BluetoothDevice(
                deviceId: UUID().uuidString,
                name: info.1,
                type: info.0,
                rssi: -50,
                lastSeen: Date(),
                isSimulated: true,
                companyID: nil,
                manufacturer: nil
            )
            // Stagger notifications slightly
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.0) {
                self.sendPrivacyAlert(for: device)

                // Add to current session dashboard
                if !self.detectedDevices.contains(where: { $0.deviceId == device.deviceId }) {
                    self.detectedDevices.append(device)
                }
                self.saveToSwiftDataHistory(device: device)
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Present visual native iOS notification banner and play sound even in foreground
        completionHandler([.banner, .list, .sound, .badge])
    }
}
