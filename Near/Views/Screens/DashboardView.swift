//
//  DashboardView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData
internal import CoreLocation

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DetectedDevice.timestamp, order: .reverse) private var historicalDevices: [DetectedDevice]
    @ObservedObject var btManager = BluetoothManager.shared
    
    @AppStorage("hasAcceptedRadarModeWarning") private var hasAcceptedRadarModeWarning = false
    @State private var showRadarWarning = false
    @State private var showLocationSettingsAlert = false
    
    var body: some View {
        NavigationStack {
            ZCenterContainer {
                Group {
                    if historicalDevices.isEmpty && btManager.detectedDevices.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "shield.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.6))
                                .symbolEffect(.pulse, options: .repeating)
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
                            if !btManager.detectedDevices.isEmpty {
                                Section(header: Text("Currently Nearby").font(.subheadline).foregroundColor(.secondary)) {
                                    ForEach(btManager.detectedDevices) { device in
                                        NavigationLink(value: device) {
                                            HStack(spacing: 12) {
                                                DeviceIconView(icon: iconForType(device.type), color: colorForType(device.type))
                                                    .frame(width: 32, height: 32)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(device.name)
                                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                        .foregroundColor(.primary)
                                                    
                                                    let typeName = displayNameForType(device.type)
                                                    if !device.name.contains(typeName) {
                                                        Text(typeName)
                                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "wifi")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(colorForRssi(device.rssi))
                                                        Text("\(device.rssi) dBm")
                                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                                            .foregroundColor(colorForRssi(device.rssi))
                                                        
                                                        Text("•")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.secondary.opacity(0.5))
                                                        
                                                        Image(systemName: "location")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.secondary)
                                                        Text(String(format: "%.1fm", device.estimatedDistance))
                                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 2)
                                        }
                                    }
                                }
                            }
                            
                            if !historicalDevices.isEmpty {
                                Section(header: Text("Recent Detections").font(.subheadline).foregroundColor(.secondary)) {
                                    ForEach(historicalDevices.prefix(10)) { device in
                                        NavigationLink(destination: DeviceDetailView(device: device)) {
                                            HStack(spacing: 12) {
                                                DeviceIconView(icon: iconForType(device.type), color: colorForType(device.type))
                                                    .frame(width: 32, height: 32)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    HStack(spacing: 4) {
                                                        Text(device.name)
                                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                            .foregroundColor(.primary)
                                                        
                                                        if device.isStarred {
                                                            Image(systemName: "star.fill")
                                                                .foregroundColor(.yellow)
                                                                .font(.system(size: 12))
                                                        }
                                                    }
                                                    
                                                    let typeName = displayNameForType(device.type)
                                                    if !device.name.contains(typeName) {
                                                        Text(typeName)
                                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    HStack(spacing: 6) {
                                                        // Time
                                                        Image(systemName: "clock")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.secondary)
                                                        Text(device.timestamp.formatted(date: .omitted, time: .shortened))
                                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                        
                                                        Text("•")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.secondary.opacity(0.5))
                                                        
                                                        // Signal strength (RSSI)
                                                        Image(systemName: "wifi")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(colorForRssi(device.rssi))
                                                        Text("\(device.rssi) dBm")
                                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                                            .foregroundColor(colorForRssi(device.rssi))
                                                        
                                                        Text("•")
                                                            .font(.system(size: 11))
                                                            .foregroundColor(.secondary.opacity(0.5))
                                                        
                                                        // Proximity
                                                        Image(systemName: "location")
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.secondary)
                                                        Text(String(format: "%.1fm", estimatedDistance(for: device.rssi)))
                                                            .font(.system(size: 11, weight: .medium, design: .rounded))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            .padding(.vertical, 2)
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
                            }
                        }
                        .listStyle(.insetGrouped)
                        .navigationDestination(for: BluetoothDevice.self) { device in
                            let historyDevice = historicalDevices.first(where: { $0.deviceId == device.deviceId }) ?? DetectedDevice(
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
                            DeviceDetailView(device: historyDevice)
                        }
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
                        if !btManager.continueScanInBackground {
                            if btManager.locationAuthorizationStatus == .notDetermined {
                                btManager.requestLocationPermission()
                            } else if btManager.locationAuthorizationStatus != .authorizedAlways {
                                showLocationSettingsAlert = true
                            } else if !hasAcceptedRadarModeWarning {
                                showRadarWarning = true
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                                    btManager.continueScanInBackground = true
                                }
                            }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                                btManager.continueScanInBackground = false
                            }
                        }
                    } label: {
                        Image(systemName: btManager.continueScanInBackground ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                            .foregroundColor(btManager.continueScanInBackground ? .green : .gray)
                            .font(.system(size: 17))
                    }
                }
            }
            .alert("Enable Radar Mode?", isPresented: $showRadarWarning) {
                Button("Cancel", role: .cancel) {
                }
                Button("Accept") {
                    hasAcceptedRadarModeWarning = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0)) {
                        btManager.continueScanInBackground = true
                    }
                }
            } message: {
                Text("The app will scan for devices in the background and app notifies you when smart glasses are nearby")
            }
            .alert("Location Access Required", isPresented: $showLocationSettingsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Radar Mode requires 'Always' location access to scan in the background. Please change this in Settings.")
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
                            .frame(width: 20, height: 20)
                            .frame(width: 32, height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(device.name)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                if device.isStarred {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 12))
                                }
                            }
                            
                            HStack(spacing: 6) {
                                // Time
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(device.timestamp.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                                
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                // Signal strength (RSSI)
                                Image(systemName: "wifi")
                                    .font(.system(size: 10))
                                    .foregroundColor(colorForRssi(device.rssi))
                                Text("\(device.rssi) dBm")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(colorForRssi(device.rssi))
                                
                                Text("•")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary.opacity(0.5))
                                
                                // Proximity
                                Image(systemName: "location")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1fm", estimatedDistance(for: device.rssi)))
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
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
