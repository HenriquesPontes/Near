//
//  DeviceDetailView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData
#if os(iOS)
import AudioToolbox
#endif

struct DeviceDetailView: View {
    let device: DetectedDevice
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var btManager = BluetoothManager.shared
    @ObservedObject var trustedManager = TrustedDeviceManager.shared
    
    @State private var currentRssi: Int = -80
    @State private var rssiHistory: [Int] = []
    @State private var trackingTask: Task<Void, Never>? = nil
    @State private var pulseScale: CGFloat = 1.0
    
    // For Tracking UI
    @State private var showTrackerView = false
    

    
    // Proximity Category (Hot & Cold)
    private var proximityStatus: (text: LocalizedStringKey, color: Color, description: LocalizedStringKey) {
        if currentRssi >= -60 {
            return ("EXTREMELY CLOSE (HOT)", .red, "The smart glasses are likely on a person right next to you.")
        } else if currentRssi >= -75 {
            return ("NEARBY (WARM)", .orange, "The device is in the immediate vicinity (same room or table).")
        } else if currentRssi >= -88 {
            return ("MID-RANGE (COOL)", .yellow, "Signal is moderate. The device is within 5-10 meters.")
        } else {
            return ("DISTANT (COLD)", .blue, "Weak signal detected. The device is far or shielded.")
        }
    }
    
    var body: some View {
            List {
                // 1. DEVICE HEADER
                Section {
                    VStack(spacing: 8) {
                        DeviceIconView(icon: iconForType(device.type), color: colorForType(device.type))
                            .frame(width: 64, height: 64)
                        
                        VStack(spacing: 4) {
                            Text(device.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            let typeName = displayNameForType(device.type, manufacturer: device.manufacturer)
                            let mfgName = device.manufacturer ?? String(localized: "Unknown Manufacturer")
                            let subtitle = (typeName == mfgName) ? typeName : (device.name.contains(typeName) ? mfgName : "\(typeName) • \(mfgName)")
                            Text(subtitle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text("ID: \(device.deviceId)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary.opacity(0.4))
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .fullScreenCover(isPresented: $showTrackerView) {
                    DeviceTrackerView(device: device)
                }
                
                // DEVICE INFO
                Section(header: Text("Device Info")) {
                    HStack {
                        Text("Manufacturer")
                            .font(.system(size: 15, weight: .medium))
                        Spacer()
                        if let manufacturer = device.manufacturer {
                            Text(manufacturer)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unknown Manufacturer")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                    if let companyID = device.companyID {
                        HStack {
                            Text("Company Identifier")
                                .font(.system(size: 15, weight: .medium))
                            Spacer()
                            Text(String(format: "0x%04X", companyID))
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 2. SIGNAL TREND (LINE CHART)
                Section(header: Text("Signal Strength")) {
                    HStack {
                        Label("Signal strength over time", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(currentRssi) dBm")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(proximityStatus.color)
                    }
                    
                    // Live Signal Line Graph
                    ZStack {
                        Color(UIColor.secondarySystemBackground)
                            .cornerRadius(12)
                        
                        if rssiHistory.count > 1 {
                            SignalHistoryChart(history: rssiHistory)
                                .stroke(proximityStatus.color.opacity(0.8), lineWidth: 2)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 8)
                        } else {
                            Text("Calibrating BLE waves...")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 120)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 8)
                }
                
                // 3. HOT & COLD PROXIMITY FINDER
                Section(header: Text("Proximity Radar")) {
                    ZStack {
                        // Background Radar Rings
                        Circle()
                            .stroke(proximityStatus.color.opacity(0.15), lineWidth: 2)
                            .frame(width: 140, height: 140)
                        Circle()
                            .stroke(proximityStatus.color.opacity(0.25), lineWidth: 2)
                            .frame(width: 100, height: 100)
                        Circle()
                            .stroke(proximityStatus.color.opacity(0.4), lineWidth: 2)
                            .frame(width: 60, height: 60)
                        
                        // Core locator ring
                        Circle()
                            .fill(proximityStatus.color)
                            .frame(width: 20, height: 20)
                            .scaleEffect(pulseScale)
                            .shadow(color: proximityStatus.color, radius: 8)
                            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseScale)
                            .onAppear {
                                pulseScale = 1.3
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(proximityStatus.text)
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(proximityStatus.color)
                        
                        Text("Estimated distance: ~\(String(format: "%.1f", estimatedDistance(for: currentRssi))) meters")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(proximityStatus.description)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    
                    // Precision Finding Button
                    Button {
                        showTrackerView = true
                    } label: {
                        HStack {
                            Image("Map_Pin")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundColor(colorForType(device.type))
                            
                            Text("Trace Device")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Note: Distance tracking relies on Bluetooth signals which can fluctuate. False positives in distance estimation may occur due to physical obstructions.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                }
                
                // 4. PRIVACY RISK PROFILE
                Section(header: Text("Privacy Threat Profile")) {
                    riskRow(title: "Video Capture Capabilities", desc: videoDescription(for: device.type), danger: hasCamera(for: device.type))
                    riskRow(title: "Audio Capture Arrays", desc: audioDescription(for: device.type), danger: hasMic(for: device.type))
                    riskRow(title: "Display / HUD Capabilities", desc: hudDescription(for: device.type), danger: false)
                }
                
                // 5. WHITELIST / IGNORE BUTTON
                Section {
                    Button(role: .destructive) {
                        // Add to ignoredDevices dictionary in BluetoothManager
                        let displayName = "\(displayNameForType(device.type, manufacturer: device.manufacturer)) (\(device.name))"
                        btManager.ignoreDevice(id: device.deviceId, name: displayName)
                        
                        // Delete from SwiftData database
                        modelContext.delete(device)
                        try? modelContext.save()
                        
                        dismiss()
                    } label: {
                        HStack {
                            Text("Ignore Device (Add to Whitelist)")
                                .font(.system(size: 16, weight: .regular))
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.backgroundColor)
            .listRowBackground(DesignSystem.cardBackground)
        .navigationTitle("Device Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                let isTrusted = trustedManager.isTrusted(id: device.deviceId)
                Button {
                    if isTrusted {
                        trustedManager.untrustDevice(id: device.deviceId)
                        device.isStarred = false
                    } else {
                        trustedManager.trustDevice(id: device.deviceId, name: device.name)
                        device.isStarred = true
                    }
                    try? modelContext.save()
                } label: {
                    if isTrusted {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .contentTransition(.identity)
                    } else {
                        Image("Star")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .opacity(device.isStarred ? 1.0 : 0.5)
                            .foregroundColor(device.isStarred ? .yellow : .gray)
                            .contentTransition(.identity)
                    }
                }
                .buttonStyle(.plain)
                .animation(nil, value: isTrusted)
            }
        }
        .onAppear {
            currentRssi = device.rssi
            rssiHistory = Array(repeating: device.rssi, count: 10)
            startTracking()
        }
        .onDisappear {
            stopTracking()
        }
    }
    
    private func startTracking() {
        trackingTask = Task {
            while !Task.isCancelled {
                // Find if there is an active BLE update for this device ID
                var targetDev = btManager.detectedDevices.first(where: { $0.deviceId == device.deviceId })
                if targetDev == nil {
                    // Fallback to closest device of same type if MAC rotated
                    targetDev = btManager.detectedDevices.filter({ $0.type == device.type }).max(by: { $0.rssi < $1.rssi })
                }
                
                if let activeDev = targetDev {
                    currentRssi = activeDev.rssi
                }
                
                // Append and maintain last 20 signals
                rssiHistory.append(currentRssi)
                if rssiHistory.count > 20 {
                    rssiHistory.removeFirst()
                }
                
                
                // Dynamic interval based on proximity
                let interval: Double
                if currentRssi >= -60 {
                    interval = 0.2
                } else if currentRssi >= -75 {
                    interval = 0.5
                } else if currentRssi >= -88 {
                    interval = 1.0
                } else {
                    interval = 2.0
                }
                
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    private func stopTracking() {
        trackingTask?.cancel()
        trackingTask = nil
    }
    
    
    
    private func hasCamera(for type: String) -> Bool {
        return type == "rayban_meta" || type == "vision_pro" || type == "snap_spectacles" || type == "google_glass" || type == "samsung_glasses"
    }
    
    private func hasMic(for type: String) -> Bool {
        return true
    }
    
    private func videoDescription(for type: String) -> LocalizedStringKey {
        switch type {
        case "rayban_meta":
            return "Dual 12MP Ultra-wide cameras. Records 1080p video with white LED active capture indicator (often taped over by covert users)."
        case "vision_pro":
            return "Stereoscopic 3D cameras. Captures spatial videos and environment depth data continuously for digital twinning."
        case "snap_spectacles":
            return "AR capture cameras. Auto-syncs shorts directly to Snapchat cloud networks."
        case "google_glass":
            return "POV camera capable of recording 720p/1080p video and photos directly to local storage."
        case "samsung_glasses":
            return "Smart eyewear camera. Potential for discrete photo or video recording."
        default:
            return "Unknown camera system. May capture pictures or video streams anonymously."
        }
    }
    
    private func audioDescription(for type: String) -> LocalizedStringKey {
        switch type {
        case "rayban_meta":
            return "Custom 5-mic array for spatial audio capturing. Highly directional and sensitive."
        case "vision_pro":
            return "Dual-driver audio pods with spatial audio calibration. Multi-microphone recording."
        case "snap_spectacles":
            return "Dual microphones for voice recognition and voice clip logging."
        case "google_glass":
            return "Built-in microphone for voice commands and audio recording."
        case "samsung_glasses":
            return "Microphone array for voice assistance and environmental audio capturing."
        default:
            return "Standard microphone system. Capable of surrounding room conversation recording."
        }
    }
    
    private func hudDescription(for type: String) -> LocalizedStringKey {
        switch type {
        case "rayban_meta":
            return "No display/HUD. Emits audio notifications and has open-ear speakers."
        case "vision_pro":
            return "Dual micro-OLED displays (4K resolution per eye). Includes external EyeSight screen showing digital eyes."
        case "snap_spectacles":
            return "Dual Waveguide displays with 2000 nits brightness showing augmented reality projections."
        case "google_glass":
            return "Prism projector display creating a semi-transparent HUD in the wearer's peripheral vision."
        case "samsung_glasses":
            return "Likely features a micro-projector or waveguide HUD for augmented reality."
        default:
            return "No display HUD detected. Audio/Radio communication channel only."
        }
    }
    
    private func riskRow(title: LocalizedStringKey, desc: LocalizedStringKey, danger: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(danger ? "Warning" : "Shield_Check")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(danger ? .red : .green)
                .font(.system(size: 16))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, 4)
    }
}
#Preview {
    DeviceDetailView(device: DetectedDevice(
        deviceId: "RB-META-4892",
        name: "Ray-Ban Meta #4892",
        type: "rayban_meta",
        timestamp: Date(),
        rssi: -70,
        isStarred: true,
        threatLevel: "High",
        isSimulated: false
    ))
    .preferredColorScheme(.dark)
}
