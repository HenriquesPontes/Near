import Foundation
import Combine

struct TrustedDevice: Codable, Identifiable, Hashable {
    var id: String { deviceId }
    let deviceId: String
    let name: String
    let addedAt: Date
}

class TrustedDeviceManager: ObservableObject {
    static let shared = TrustedDeviceManager()
    
    @Published var trustedDevices: [TrustedDevice] = []
    
    private let defaultsKey = "NearTrustedDevices"
    
    private init() {
        loadDevices()
    }
    
    func trustDevice(id: String, name: String) {
        if !isTrusted(id: id) {
            let newDevice = TrustedDevice(deviceId: id, name: name, addedAt: Date())
            trustedDevices.append(newDevice)
            saveDevices()
        }
    }
    
    func untrustDevice(id: String) {
        trustedDevices.removeAll { $0.deviceId == id }
        saveDevices()
    }
    
    func isTrusted(id: String) -> Bool {
        return trustedDevices.contains { $0.deviceId == id }
    }
    
    private func saveDevices() {
        if let encoded = try? JSONEncoder().encode(trustedDevices) {
            UserDefaults.standard.set(encoded, forKey: defaultsKey)
        }
    }
    
    private func loadDevices() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode([TrustedDevice].self, from: data) {
            self.trustedDevices = decoded
        }
    }
}
