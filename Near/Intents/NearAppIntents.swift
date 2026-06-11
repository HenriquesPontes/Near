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
    }
}
