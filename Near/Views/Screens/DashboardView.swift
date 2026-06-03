//
//  DashboardView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @ObservedObject var btManager = BluetoothManager.shared
    
    @State private var showingScan = false
    @State private var showingSettings = false
    @State private var showingInfo = false
    @State private var selectedDevice: DetectedDevice? = nil
    
    var body: some View {
        NavigationStack {
            ZCenterContainer {
                VStack(spacing: 20) {
                    
                    // Alert History List
                    if historicalDevices.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "shield.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.6))
                            Text("No smart glasses detected yet")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            Text("Tap SCAN below to scan for nearby devices.")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(historicalDevices.prefix(15)) { device in
                                Button {
                                    selectedDevice = device
                                } label: {
                                    HStack(spacing: 16) {
                                        // Device Type Icon
                                        Image(systemName: iconForType(device.type))
                                            .font(.system(size: 18))
                                            .foregroundColor(.white)
                                            .frame(width: 38, height: 38)
                                            .background(colorForType(device.type).opacity(0.8))
                                            .cornerRadius(10)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 6) {
                                                Text(device.name)
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)

                                            }
                                            
                                            Text("Detected \(device.timestamp, format: .dateTime.hour().minute().second())")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(device.threatLevel)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundColor(device.threatLevel == "High" ? .red : .yellow)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill((device.threatLevel == "High" ? Color.red : Color.yellow).opacity(0.15))
                                            )
                                        
                                        // Star Toggle (Favorite)
                                        Button {
                                            device.isStarred.toggle()
                                            try? modelContext.save()
                                        } label: {
                                            Image(systemName: device.isStarred ? "star.fill" : "star")
                                                .font(.system(size: 16))
                                                .foregroundColor(device.isStarred ? .yellow : .gray)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                    .padding(.vertical, 8)
                                }
                                .listRowBackground(DesignSystem.cardBackground)
                                .listRowSeparatorTint(DesignSystem.borderStroke)
                            }
                            .onDelete(perform: deleteDevices)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
                    
                    // Mockup Summary Text Box
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Privacy Awareness Active")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Your device is monitoring BLE radio emissions from wearable camera systems nearby.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(DesignSystem.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(DesignSystem.borderStroke, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        // SCAN Button (Blue)
                        Button {
                            showingScan = true
                        } label: {
                            Text("Start Scanning")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(DesignSystem.primaryBlue)
                                .cornerRadius(26)
                        }
                        
                        // Setting Button (Light Gray)
                        Button {
                            showingSettings = true
                        } label: {
                            Text("Settings")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(DesignSystem.itemBackground)
                                .cornerRadius(26)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 26)
                                        .stroke(DesignSystem.borderStroke, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Near")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top Left Info Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.white)
                            .font(.system(size: 17))
                    }
                }
                
                // Top Right Background Scanning Toggle Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        btManager.continueScanInBackground.toggle()
                    } label: {
                        Image(systemName: btManager.continueScanInBackground ? "bolt.shield.fill" : "bolt.shield")
                            .foregroundColor(btManager.continueScanInBackground ? .green : .white)
                            .font(.system(size: 17))
                    }
                }
            }
            // Navigation Links / Sheets
            .fullScreenCover(isPresented: $showingScan) {
                ScanRadarView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingInfo) {
                PrivacyInfoView()
            }
            .sheet(item: $selectedDevice) { device in
                DeviceDetailView(device: device)
            }
            // Listen to BLE Manager alerts
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NewDeviceDetectedHistory"))) { notification in
                if let btDevice = notification.object as? BluetoothDevice {
                    addHistoricalLog(device: btDevice)
                }
            }
        }
    }
    
    private func addHistoricalLog(device: BluetoothDevice) {
        // Verify duplicate (within last 30 seconds) to avoid spamming the log list
        let checkTime = Date().addingTimeInterval(-30)
        let deviceId = device.deviceId
        
        let descriptor = FetchDescriptor<DetectedDevice>(
            predicate: #Predicate { $0.deviceId == deviceId && $0.timestamp > checkTime }
        )
        
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            // Already logged recently, just update RSSI and timestamp
            if let first = existing.first {
                first.rssi = device.rssi
                first.timestamp = Date()
                try? modelContext.save()
            }
            return
        }
        
        let newLog = DetectedDevice(
            deviceId: device.deviceId,
            name: device.name,
            type: device.type,
            rssi: device.rssi,
            isStarred: false,
            threatLevel: device.threatLevel,
            isSimulated: device.isSimulated
        )
        
        modelContext.insert(newLog)
        try? modelContext.save()
    }
    
    private func deleteDevices(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(historicalDevices[index])
            }
            try? modelContext.save()
        }
    }
    }

// Info / About Screen
struct PrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZCenterContainer {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Near App Privacy Awareness")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        Text("Near is a utility designed to detect and log radio emissions from nearby smart glasses and optical wearables.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                        
                        Text("Why is this needed?")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        Text("Camera-integrated smart glasses make it incredibly easy to record audio and video discreetly in public spaces, gyms, and private environments. Near continuously monitors BLE advertisements to identify these devices before they capture your image.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                        
                        Text("How to respond if alerted:")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 10)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            bulletPoint(number: "1", text: "Visually scan for the device. Look for someone wearing glasses with thicker frames or a tiny lens on the corner hinges.")
                            bulletPoint(number: "2", text: "Look for recording indicators. Devices like Ray-Ban Meta glasses have a capture LED light on the frame. If it's solid white, it is actively recording or streaming.")
                            bulletPoint(number: "3", text: "Politely ask the wearer to cover the camera or remove their glasses if in a private space where recording is prohibited.")
                        }
                        
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("About Near")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func bulletPoint(number: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .lineSpacing(2)
        }
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}
