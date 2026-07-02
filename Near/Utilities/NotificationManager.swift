import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
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
    
    func sendDeviceDetectedNotification(device: BluetoothDevice, deviceCount: Int = 1) {
        let content = UNMutableNotificationContent()
        
        var baseTitle = String(localized: "Device Nearby")
        if device.threatLevel == "High" {
            baseTitle = String(localized: "Spyware Detected")
        } else if device.threatLevel == "Medium" {
            baseTitle = String(localized: "Suspicious Device")
        } else {
            let typeName = displayNameForType(device.type, manufacturer: device.manufacturer)
            let mfgName = device.manufacturer ?? String(localized: "Unknown Manufacturer")
            baseTitle = (typeName == mfgName) ? typeName : (device.name.contains(typeName) ? mfgName : "\(typeName) • \(mfgName)")
        }
        
        content.title = "\(baseTitle) ⚠️"
        content.body = "\(String(localized: "Detected:")) \(device.name)"
        content.sound = .default
        let enableAppBadge = UserDefaults.standard.object(forKey: "enableAppBadge") as? Bool ?? false
        if enableAppBadge {
            content.badge = NSNumber(value: deviceCount)
        } else {
            content.badge = NSNumber(value: 0)
        }
        
        // Add custom data
        content.userInfo = ["deviceName": device.name, "deviceCount": deviceCount]
        
        content.threadIdentifier = "near_device_detection"
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .active
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: device.deviceId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show in notification center list, update badge, and show banner/sound even while using the app
        let enableAppBadge = UserDefaults.standard.object(forKey: "enableAppBadge") as? Bool ?? false
        if enableAppBadge {
            completionHandler([.banner, .sound, .list, .badge])
        } else {
            completionHandler([.banner, .sound, .list])
        }
    }
}
