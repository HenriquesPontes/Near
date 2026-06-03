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
    
    @State private var currentRssi: Int = -80
    @State private var rssiHistory: [Int] = []
    @State private var timer: Timer? = nil
    @State private var trackerActive = false
    @State private var pulseScale: CGFloat = 1.0
    
    // Convert current RSSI to estimated distance
    private var estimatedDistance: Double {
        let txPower = -59.0
        if currentRssi == 0 { return -1.0 }
        let ratio = Double(currentRssi) * 1.0 / txPower
        if ratio < 1.0 {
            return pow(ratio, 10.0)
        } else {
            return (0.89976) * pow(ratio, 7.7095) + 0.111
        }
    }
    
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
        NavigationStack {
            ZCenterContainer {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. DEVICE HEADER
                        VStack(spacing: 12) {
                            Image(systemName: iconForType(device.type))
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(colorForType(device.type))
                                .clipShape(Circle())
                                .shadow(color: colorForType(device.type).opacity(0.4), radius: 12)
                            
                            VStack(spacing: 4) {
                                Text(device.name)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("ID: \(device.deviceId)")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 16)
                        
                        // 2. SIGNAL TREND (LINE CHART)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Signal strength over time", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(currentRssi) dBm")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(proximityStatus.color)
                            }
                            
                            // Live Signal Line Graph
                            ZStack {
                                Color.black.opacity(0.3)
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
                        }
                        .padding(16)
                        .background(DesignSystem.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DesignSystem.borderStroke, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // 3. HOT & COLD PROXIMITY FINDER
                        VStack(spacing: 16) {
                            Text("PROXIMITY RADAR")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                // Background Radar Rings
                                Circle()
                                    .stroke(proximityStatus.color.opacity(0.15), lineWidth: 2)
                                    .frame(width: 160, height: 160)
                                Circle()
                                    .stroke(proximityStatus.color.opacity(0.25), lineWidth: 2)
                                    .frame(width: 110, height: 110)
                                Circle()
                                    .stroke(proximityStatus.color.opacity(0.4), lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                
                                // Core locator ring
                                Circle()
                                    .fill(proximityStatus.color)
                                    .frame(width: 24, height: 24)
                                    .scaleEffect(pulseScale)
                                    .shadow(color: proximityStatus.color, radius: 10)
                                    .onAppear {
                                        withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                            pulseScale = 1.3
                                        }
                                    }
                            }
                            .frame(height: 180)
                            
                            VStack(spacing: 6) {
                                Text(proximityStatus.text)
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .foregroundColor(proximityStatus.color)
                                
                                Text("Estimated distance: ~\(String(format: "%.1f", estimatedDistance)) meters")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(proximityStatus.description)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Audio feedback tracker toggle
                            Button {
                                trackerActive.toggle()
                            } label: {
                                HStack {
                                    Image(systemName: trackerActive ? "volume.3.fill" : "volume.slash.fill")
                                    Text(trackerActive ? "Audio Guidance Active" : "Enable Audio Guidance")
                                }
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(trackerActive ? Color.green.opacity(0.8) : DesignSystem.primaryBlue.opacity(0.8))
                                .cornerRadius(20)
                            }
                        }
                        .padding(18)
                        .background(DesignSystem.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DesignSystem.borderStroke, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // 4. PRIVACY RISK PROFILE
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PRIVACY THREAT PROFILE")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                riskRow(title: "Video Capture Capabilities", desc: videoDescription(for: device.type), danger: hasCamera(for: device.type))
                                Divider().background(Color.white.opacity(0.08))
                                riskRow(title: "Audio Capture Arrays", desc: audioDescription(for: device.type), danger: hasMic(for: device.type))
                                Divider().background(Color.white.opacity(0.08))
                                riskRow(title: "Display / HUD Capabilities", desc: hudDescription(for: device.type), danger: false)
                            }
                        }
                        .padding(18)
                        .background(DesignSystem.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(DesignSystem.borderStroke, lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // 5. WHITELIST / IGNORE BUTTON
                        Button(role: .destructive) {
                            // Add to ignoredDevices dictionary in BluetoothManager
                            let displayName = "\(displayNameForType(device.type)) (\(device.name))"
                            btManager.ignoreDevice(id: device.deviceId, name: displayName)
                            
                            // Delete from SwiftData database
                            modelContext.delete(device)
                            try? modelContext.save()
                            
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "eye.slash.fill")
                                Text("Ignore Device (Add to Whitelist)")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(DesignSystem.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
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
    }
    
    private func startTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            // Find if there is an active BLE update for this device ID
            if let activeDev = btManager.detectedDevices.first(where: { $0.deviceId == device.deviceId }) {
                currentRssi = activeDev.rssi
            }
            
            // Append and maintain last 20 signals
            rssiHistory.append(currentRssi)
            if rssiHistory.count > 20 {
                rssiHistory.removeFirst()
            }
            
            // Play ping tone if guidance is active
            if trackerActive {
                playGuidanceBeep()
            }
        }
    }
    
    private func stopTracking() {
        timer?.invalidate()
        timer = nil
    }
    
    private func playGuidanceBeep() {
        // Emit visual feedback or trigger system beep sounds.
        // On simulator, we can simulate audio frequency speed matching the RSSI:
        // Strong RSSI (-50) -> very fast double beeps
        // Weak RSSI (-95) -> slow, lazy single beeps
        let systemSoundID: UInt32 = 1104 // Standard system click/tap sound
        #if os(iOS)
        AudioServicesPlaySystemSound(systemSoundID)
        #endif
    }
    
    
    private func hasCamera(for type: String) -> Bool {
        return type == "rayban_meta" || type == "vision_pro" || type == "snap_spectacles"
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
        default:
            return "No display HUD detected. Audio/Radio communication channel only."
        }
    }
    
    private func riskRow(title: LocalizedStringKey, desc: LocalizedStringKey, danger: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: danger ? "exclamationmark.triangle.fill" : "checkmark.shield.fill")
                .foregroundColor(danger ? .red : .green)
                .font(.system(size: 16))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineSpacing(2)
            }
        }
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
