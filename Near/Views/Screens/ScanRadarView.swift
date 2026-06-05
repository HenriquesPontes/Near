//
//  ScanRadarView.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI
import SwiftData
internal import CoreLocation

struct ScanRadarView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @ObservedObject var btManager = BluetoothManager.shared
    
    @State private var rotationAngle: Double = 0.0
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.8
    @State private var selectedDevice: BluetoothDevice? = nil
    @State private var showLocationPermissionPrompt: Bool = false
    @State private var showLocationSettingsPrompt: Bool = false
    
    var body: some View {
        ZCenterContainer {
            VStack(spacing: 16) {
                
                // RADAR SCREEN
                GeometryReader { geo in
                    let radarSize = max(geo.size.width - 40, 0)
                    ZStack {
                        // Concord Rings
                        ForEach(1...4, id: \.self) { ring in
                            Circle()
                                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                .frame(width: CGFloat(ring) * radarSize / 4)
                        }
                        
                        // Cross lines
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: geo.size.height / 2))
                            path.addLine(to: CGPoint(x: geo.size.width - 20, y: geo.size.height / 2))
                            path.move(to: CGPoint(x: geo.size.width / 2, y: 20))
                            path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height - 20))
                        }
                        .stroke(Color.blue.opacity(0.08), lineWidth: 1)
                        
                        // Sonar Sweep Wave (Rippling Out)
                        if btManager.isScanning {
                            Circle()
                                .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                                .scaleEffect(rippleScale)
                                .opacity(rippleOpacity)
                                .onAppear {
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        rippleScale = 0.5
                                        rippleOpacity = 0.8
                                    }
                                    withAnimation(Animation.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                                        rippleScale = 1.0
                                        rippleOpacity = 0.0
                                    }
                                }
                            
                            // Radar Sweep Shader Line (Gradient Sweep)
                            Circle()
                                .fill(
                                    AngularGradient(
                                        gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.0)]),
                                        center: .center,
                                        angle: .degrees(0)
                                    )
                                )
                                .frame(width: radarSize, height: radarSize)
                                .rotationEffect(.degrees(rotationAngle))
                                .onAppear {
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        rotationAngle = 0.0
                                    }
                                    withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                                        rotationAngle = 360.0
                                    }
                                }
                        }
                        
                        // Center Core (Scanner Node)
                        Circle()
                            .fill(DesignSystem.primaryBlue)
                            .frame(width: 14, height: 14)
                            .shadow(color: DesignSystem.primaryBlue, radius: 8)
                        
                        // Detected Device Ping Dots
                        if btManager.isScanning {
                            ForEach(btManager.detectedDevices) { device in
                                let pos = position(for: device, in: geo.size)
                                DevicePingNode(device: device) {
                                    selectedDevice = device
                                }
                                .position(pos)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .aspectRatio(1.0, contentMode: .fit)
                .padding(20)
                
                // STATUS TEXT
                VStack(spacing: 4) {
                    if btManager.isScanning {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .shadow(color: .green, radius: 4)
                            Text("SCANNING ACTIVE")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        Text("\(btManager.detectedDevices.count) smart wearable emissions in range")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    } else {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("SCANNING PAUSED")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                        }
                        Text("Tap Play to resume privacy detection scan")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
                
                // ACTIVE DETECTED LIST (Horizontal scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(btManager.detectedDevices) { device in
                            Button {
                                selectedDevice = device
                            } label: {
                                detectedDeviceCard(for: device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 110)
                
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Button {
                            withAnimation {
                                toggleScanningWithLocationCheck()
                            }
                        } label: {
                            Text(btManager.isScanning ? "Stop Scanning" : "Resume Scanning")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(btManager.isScanning ? DesignSystem.activeRed : DesignSystem.primaryBlue)
                                .cornerRadius(26)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(DesignSystem.backgroundColor)
            }
        }
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    DeviceFiltersSettingsView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            handleScanOnAppear()
        }
        .onChange(of: btManager.locationAuthorizationStatus) { newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                if !btManager.isScanning {
                    btManager.startScanning()
                }
            }
        }
        .onDisappear {
            if !btManager.continueScanInBackground {
                btManager.stopScanning()
            }
        }
        .alert("Location Access Required", isPresented: $showLocationPermissionPrompt) {
            Button("Allow Location") {
                btManager.requestLocationPermission()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Nearby scanning uses location and Bluetooth to detect nearby devices. Please allow location access so scanning can start.")
        }
        .alert("Location Access Denied", isPresented: $showLocationSettingsPrompt) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Location permission is denied. Open Settings and grant location access to use the scan feature.")
        }
        .navigationDestination(item: $selectedDevice) { device in
            // Map the transient BluetoothDevice to a temporary DetectedDevice for the details view
            let tempDevice = DetectedDevice(
                deviceId: device.deviceId,
                name: device.name,
                type: device.type,
                timestamp: device.lastSeen,
                rssi: device.rssi,
                isStarred: device.isStarred,
                threatLevel: device.threatLevel,
                isSimulated: device.isSimulated,
                companyID: device.companyID,
                manufacturer: device.manufacturer
            )
            DeviceDetailView(device: tempDevice)
        }
    }
    
    private func handleScanOnAppear() {
        switch btManager.locationAuthorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            btManager.startScanning()
        case .denied, .restricted:
            showLocationSettingsPrompt = true
        default:
            showLocationPermissionPrompt = true
        }
    }
    
    private func toggleScanningWithLocationCheck() {
        if btManager.isScanning {
            btManager.continueScanInBackground = false
            btManager.stopScanning()
            return
        }
        switch btManager.locationAuthorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            btManager.startScanning()
        case .denied, .restricted:
            showLocationSettingsPrompt = true
        default:
            showLocationPermissionPrompt = true
        }
    }
    
    // Calculates dot position
    private func detectedDeviceCard(for device: BluetoothDevice) -> some View {
        let distanceLabel = String(format: "%.1f m", device.estimatedDistance)
        let rssiLabel = "RSSI: \(device.rssi) dBm"
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                DeviceIconView(icon: iconForType(device.type), color: colorForType(device.type))
                    .frame(width: 26, height: 26)
                
                Spacer()
                
                Text(distanceLabel)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(DesignSystem.primaryBlue)
            }
            
            Text(device.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(rssiLabel)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 140)
        .background(DesignSystem.itemBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DesignSystem.borderStroke, lineWidth: 1)
        )
    }
    
    private func position(for device: BluetoothDevice, in size: CGSize) -> CGPoint {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Generate a deterministic angle based on device ID string hash
        let hashValue = abs(device.deviceId.hash)
        let angle = Double(hashValue % 360) * .pi / 180.0
        
        // Map estimated distance (0m to 15m) to radius (0 to maxRadius)
        let padding: CGFloat = 30
        let maxRadius = max(min(size.width, size.height) / 2 - padding, 0)
        
        // Ensure distance ratio is normalized between 0.1 and 1.0 (to avoid overlapping center)
        let distanceRatio = min(max(device.estimatedDistance / 15.0, 0.15), 1.0)
        let radius = maxRadius * CGFloat(distanceRatio)
        
        let x = center.x + CGFloat(cos(angle)) * radius
        let y = center.y + CGFloat(sin(angle)) * radius
        
        return CGPoint(x: x, y: y)
    }
    
}
#Preview {
    ScanRadarView()
        .preferredColorScheme(.dark)
}
