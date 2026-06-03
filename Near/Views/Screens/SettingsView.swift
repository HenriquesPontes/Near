//
//  SettingsView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var btManager = BluetoothManager.shared
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @AppStorage("selectedLanguage") var selectedLanguage: String = Bundle.main.preferredLocalizations.first ?? "en"
    
    // Sensitivity UI representation
    private var sensitivityLabel: LocalizedStringKey {
        switch btManager.rssiThreshold {
        case -60...(-40):
            return "Near (Direct proximity, ~2m)"
        case -79...(-61):
            return "Medium (Same room, ~5m)"
        default:
            return "Far (Long range, ~15m)"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZCenterContainer {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // SECTION 1: Privacy Shields Alert settings
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SHIELD CONTROLS")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                ToggleRow(
                                    title: "Alert on New Devices",
                                    subtitle: "Notify when smart glasses enter your zone",
                                    icon: "bell.badge.fill",
                                    color: .blue,
                                    isOn: $btManager.alertOnNewDevices
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Label {
                                            Text("Detection Sensitivity")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        } icon: {
                                            Image(systemName: "waveform.path.ecg")
                                                .foregroundColor(.blue)
                                        }
                                        Spacer()
                                        Text(sensitivityLabel)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    Slider(value: Binding(
                                        get: { Double(btManager.rssiThreshold) },
                                        set: { btManager.rssiThreshold = Int($0) }
                                    ), in: -95...(-55), step: 5)
                                    .accentColor(.blue)
                                    
                                    Text("Higher sensitivity alerts you even for weak/distant signals, but increases potential false triggers.")
                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                            }
                            .background(DesignSystem.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.borderStroke, lineWidth: 1)
                            )
                        }
                        
                        // APPLICATION SETTINGS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("APPLICATION SETTINGS")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                HStack(spacing: 16) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .frame(width: 36, height: 36)
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(8)
                                    
                                    Text("Language")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $selectedLanguage) {
                                        Text("English").tag("en")
                                        Text("Deutsch").tag("de")
                                        Text("Français").tag("fr")
                                        Text("Español").tag("es")
                                        Text("Italiano").tag("it")
                                        Text("Português").tag("pt")
                                    }
                                    .pickerStyle(.menu)
                                    .accentColor(.blue)
                                }
                                .padding(16)
                            }
                            .background(DesignSystem.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.borderStroke, lineWidth: 1)
                            )
                        }
                        
                        // SECTION 2: DEVICE FILTERS
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DETECTED GLASSES CHANNELS")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                FilterToggleRow(
                                    title: "Ray-Ban Meta Series",
                                    description: "Discreet photo/video capturing",
                                    icon: "eye.fill",
                                    color: .red,
                                    isOn: bindingForType("rayban_meta")
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                FilterToggleRow(
                                    title: "Apple Vision Pro",
                                    description: "Spatial video & high power AR logging",
                                    icon: "arkit",
                                    color: .purple,
                                    isOn: bindingForType("vision_pro")
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                FilterToggleRow(
                                    title: "Snapchat Spectacles",
                                    description: "AR recording and sharing HUD",
                                    icon: "camera.filters",
                                    color: .yellow,
                                    isOn: bindingForType("snap_spectacles")
                                )
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                FilterToggleRow(
                                    title: "Unknown Smart Devices",
                                    description: "Generic smart wear emissions",
                                    icon: "questionmark.circle.fill",
                                    color: .gray,
                                    isOn: bindingForType("unknown")
                                )
                            }
                            .background(DesignSystem.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.borderStroke, lineWidth: 1)
                            )
                        }

                        // SECTION 3: IGNORED DEVICES (WHITELIST)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("IGNORED DEVICES (WHITELIST)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            if btManager.ignoredDevices.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No ignored devices")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.gray)
                                    Text("Devices you choose to ignore from details view will appear here.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(24)
                                .frame(maxWidth: .infinity)
                                .background(DesignSystem.cardBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(DesignSystem.borderStroke, lineWidth: 1)
                                )
                            } else {
                                VStack(spacing: 0) {
                                    let keys = Array(btManager.ignoredDevices.keys).sorted()
                                    ForEach(keys, id: \.self) { id in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(btManager.ignoredDevices[id] ?? "Unknown Device")
                                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                                    .foregroundColor(.white)
                                                Text("ID: \(id)")
                                                    .font(.system(size: 11, design: .monospaced))
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Button {
                                                withAnimation {
                                                    btManager.unignoreDevice(id: id)
                                                }
                                            } label: {
                                                Text("Restore")
                                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(DesignSystem.itemBackground)
                                                    .cornerRadius(12)
                                            }
                                        }
                                        .padding(16)
                                        
                                        if id != keys.last {
                                            Divider().background(Color.white.opacity(0.1))
                                        }
                                    }
                                }
                                .background(DesignSystem.cardBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(DesignSystem.borderStroke, lineWidth: 1)
                                )
                            }
                        }

                        // SECTION 4: LOG UTILITIES
                        VStack(alignment: .leading, spacing: 16) {
                            Text("LOG UTILITIES")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                Button {
                                    exportCSVLog()
                                } label: {
                                    HStack {
                                        Label("Export CSV Detection Log", systemImage: "square.and.arrow.up")
                                            .foregroundColor(.white)
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .padding(16)
                                }
                            }
                            .background(DesignSystem.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(DesignSystem.borderStroke, lineWidth: 1)
                            )
                        }

                        // SECTION 5: EDUCATIONAL CARD
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIVACY DISCLOSURES")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 4)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Image(systemName: "exclamationmark.shield.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                    Text("Understanding Smart Wear Risks")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Most smart glasses utilize a front-facing white LED indicator that turns solid or flashes when recording is active. However, these LEDs can be obstructed or modified.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                                
                                Text("The Near app continuously parses Bluetooth Low Energy advertisements. Ray-Ban Meta glasses emit periodic BLE pulses to negotiate data transfers, letting us detect them even if recording is not actively running.")
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.gray)
                                    .lineSpacing(4)
                            }
                            .padding(18)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.1), Color.black.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
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
        }
    }
    
    // Binding helper for Set<String> toggle
    private func bindingForType(_ type: String) -> Binding<Bool> {
        Binding(
            get: { btManager.enabledAlertTypes.contains(type) },
            set: { enabled in
                if enabled {
                    btManager.enabledAlertTypes.insert(type)
                } else {
                    btManager.enabledAlertTypes.remove(type)
                }
            }
        )
    }
    
    // CSV Export
    private func exportCSVLog() {
        let csv = LogExporter.generateCSV(from: historicalDevices)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("near_log_\(Date().timeIntervalSince1970).csv")
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activityVC, animated: true)
            }
        } catch {
            print("Failed to export CSV: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
