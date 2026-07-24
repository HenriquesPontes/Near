import AppIntents
import Foundation

struct StartScanningIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Scanning"
    static var description = IntentDescription("Starts scanning for nearby bluetooth devices.")
    
    // This allows the intent to be run without opening the app, which is good for background scanning
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        BluetoothManager.shared.startScanning()
        return .result(dialog: "Started scanning for nearby devices.")
    }
}

struct StopScanningIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Scanning"
    static var description = IntentDescription("Stops scanning for nearby bluetooth devices.")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        BluetoothManager.shared.stopScanning()
        return .result(dialog: "Stopped scanning for nearby devices.")
    }
}

struct CheckNearIntent: AppIntent {
    static var title: LocalizedStringResource = "Check for Smart Glasses"
    static var description = IntentDescription("Checks if any smart glasses or recording devices are detected nearby.")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let btManager = BluetoothManager.shared
        if !btManager.isScanning {
            btManager.startScanning()
        }
        
        let allDevices = btManager.detectedDevices
        var glassesDevices: [BluetoothDevice] = []
        
        for dev in allDevices {
            let nameLower = dev.name.lowercased()
            let typeLower = dev.type.lowercased()
            if dev.type != "unknown" || nameLower.contains("glass") || nameLower.contains("ray-ban") || nameLower.contains("meta") || typeLower.contains("glass") {
                glassesDevices.append(dev)
            }
        }
        
        if glassesDevices.isEmpty {
            return .result(dialog: "No smart glasses detected nearby.")
        } else {
            let count = glassesDevices.count
            if let nearest = glassesDevices.max(by: { $0.rssi < $1.rssi }) {
                let distString = String(format: "%.1f", nearest.estimatedDistance)
                if count == 1 {
                    return .result(dialog: "Near detected 1 \(nearest.name) approximately \(distString) meters away.")
                } else {
                    return .result(dialog: "Near detected \(count) smart glasses nearby. The closest is \(nearest.name) at approximately \(distString) meters.")
                }
            } else {
                return .result(dialog: "Near detected \(count) smart glasses nearby.")
            }
        }
    }
}

struct NearAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartScanningIntent(),
            phrases: [
                "Start scanning with \(.applicationName)",
                "Scan for devices using \(.applicationName)",
                "Begin \(.applicationName) scan"
            ],
            shortTitle: "Start Scanning",
            systemImageName: "antenna.radiowaves.left.and.right"
        )
        
        AppShortcut(
            intent: StopScanningIntent(),
            phrases: [
                "Stop scanning with \(.applicationName)",
                "Stop \(.applicationName) scan",
                "Halt device scan in \(.applicationName)"
            ],
            shortTitle: "Stop Scanning",
            systemImageName: "antenna.radiowaves.left.and.right.slash"
        )
        
        AppShortcut(
            intent: CheckNearIntent(),
            phrases: [
                "Check for smart glasses with \(.applicationName)",
                "Is anyone wearing smart glasses near me with \(.applicationName)",
                "Scan for smart glasses with \(.applicationName)",
                "Find nearby glasses using \(.applicationName)"
            ],
            shortTitle: "Check Smart Glasses",
            systemImageName: "eyeglasses"
        )
    }
}
