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
    

    
    var body: some View {
        NavigationStack {
            ZCenterContainer {
                Group {
                    if historicalDevices.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "shield.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("No smart glasses detected yet")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary.opacity(0.8))
                            Text("Tap Start Scanning below to scan for nearby devices.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(historicalDevices.prefix(10)) { device in
                                NavigationLink(destination: DeviceDetailView(device: device)) {
                                    HStack(spacing: 12) {
                                        DeviceIconView(icon: iconForType(device.type), color: colorForType(device.type))
                                            .frame(width: 24, height: 24)
                                        
                                        Text(device.name)
                                            .font(.system(size: 16, weight: .regular, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .onDelete(perform: deleteDevices)
                            
                            if historicalDevices.count > 10 {
                                NavigationLink(destination: AllResultsView()) {
                                    Text("View All Results")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 16) {
                        // Radar Status Bar
                        if btManager.continueScanInBackground {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: Color.green.opacity(0.5), radius: 3)
                                
                                Text("Privacy Awareness Active")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 4)
                        }
                        
                        // Buttons
                        VStack(spacing: 12) {
                            // SCAN Button (Blue)
                            NavigationLink(destination: ScanRadarView()) {
                                Text("Start Scanning")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(DesignSystem.primaryBlue)
                                    .cornerRadius(26)
                            }
                            
                            // Setting Button (Light Gray / Dynamic Secondary Grouped Background)
                            NavigationLink(destination: SettingsView()) {
                                Text("Settings")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .background(DesignSystem.backgroundColor)
                }
            }
            .navigationTitle("Nearby")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top Right Radar Toggle Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                            btManager.continueScanInBackground.toggle()
                        }
                    } label: {
                        Image(systemName: btManager.continueScanInBackground ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                            .foregroundColor(btManager.continueScanInBackground ? .green : .gray)
                            .font(.system(size: 17))
                    }
                }
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
                if first.manufacturer == nil {
                    first.manufacturer = device.manufacturer
                }
                if first.companyID == nil {
                    first.companyID = device.companyID
                }
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
            isSimulated: device.isSimulated,
            companyID: device.companyID,
            manufacturer: device.manufacturer
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

struct AllResultsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @State private var showingClearConfirmation = false
    
    var body: some View {
        List {
            ForEach(historicalDevices) { device in
                NavigationLink(destination: DeviceDetailView(device: device)) {
                    HStack(spacing: 12) {
                        DeviceIconView(icon: iconForType(device.type), color: colorForType(device.type))
                            .frame(width: 24, height: 24)
                        
                        Text(device.name)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
            .onDelete(perform: deleteDevices)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("All Detections")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if !historicalDevices.isEmpty {
                        Button {
                            showingClearConfirmation = true
                        } label: {
                            Text("Clear All")
                                .foregroundColor(.red)
                        }
                    }
                    EditButton()
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete all detections?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                clearAll()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func clearAll() {
        withAnimation {
            for device in historicalDevices {
                modelContext.delete(device)
            }
            try? modelContext.save()
        }
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

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
        .modelContainer(for: DetectedDevice.self, inMemory: true)
}
