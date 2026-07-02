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
    
    @State private var selectedDevice: BluetoothDevice? = nil
    @State private var showLocationPermissionPrompt: Bool = false
    @State private var showLocationSettingsPrompt: Bool = false
    @State private var navigateToAllResults: Bool = false
    
    var body: some View {
        ZCenterContainer {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // TITLE
                    if btManager.isScanning {
                        Text("Searching for Devices...")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 16)
                    } else {
                        Text("Scan Completed")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 16)
                    }
                    
                    // RADAR SCREEN
                    ZStack {
                        // Concord Rings
                        ForEach(1...4, id: \.self) { ring in
                            Circle()
                                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                                .frame(width: CGFloat(ring) * 280 / 4)
                        }
                        
                        // Cross lines
                        Path { path in
                            path.move(to: CGPoint(x: 20, y: 140))
                            path.addLine(to: CGPoint(x: 260, y: 140))
                            path.move(to: CGPoint(x: 140, y: 20))
                            path.addLine(to: CGPoint(x: 140, y: 260))
                        }
                        .stroke(Color.blue.opacity(0.08), lineWidth: 1)
                        
                        // Sonar Sweep Wave & Radar Sweep Shader (Animated via TimelineView to prevent stuttering/glitches)
                        if btManager.isScanning {
                            TimelineView(.animation) { timelineContext in
                                let time = timelineContext.date.timeIntervalSinceReferenceDate
                                
                                // Sonar Wave: Ripples out every 3 seconds
                                let waveProgress = (time.truncatingRemainder(dividingBy: 3.0) / 3.0)
                                let waveScale = 0.5 + (waveProgress * 0.5)
                                let waveOpacity = 0.8 * (1.0 - waveProgress)
                                
                                // Radar Sweep: Rotates full 360 degrees every 4 seconds
                                let sweepAngle = (time.truncatingRemainder(dividingBy: 4.0) / 4.0) * 360.0
                                
                                ZStack {
                                    Circle()
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                                        .scaleEffect(waveScale)
                                        .opacity(waveOpacity)
                                    
                                    Circle()
                                        .fill(
                                            AngularGradient(
                                                gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.0)]),
                                                center: .center,
                                                angle: .degrees(0)
                                            )
                                        )
                                        .rotationEffect(.degrees(sweepAngle))
                                }
                            }
                            .frame(width: 280, height: 280)
                        }
                        
                        // Center Core (Scanner Node)
                        Circle()
                            .fill(DesignSystem.primaryBlue)
                            .frame(width: 14, height: 14)
                            .shadow(color: DesignSystem.primaryBlue, radius: 8)
                        
                        // Detected Device Ping Dots
                        if btManager.isScanning || !btManager.detectedDevices.isEmpty {
                            ForEach(btManager.detectedDevices) { device in
                                let pos = position(for: device, in: CGSize(width: 280, height: 280))
                                DevicePingNode(device: device) {
                                    selectedDevice = device
                                }
                                .position(pos)
                            }
                        }
                    }
                    .frame(width: 280, height: 280)
                    .padding(20)
                    
                    // SUBTITLE
                    Text("Ensure Bluetooth is enabled to detect nearby smart glasses.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    // LIST OF DEVICES (vertical grouped card style matching All Detections / List style)
                    if !btManager.detectedDevices.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(Array(btManager.detectedDevices.enumerated()), id: \.element.id) { index, device in
                                Button {
                                    selectedDevice = device
                                } label: {
                                    deviceRowCard(for: device)
                                }
                                .buttonStyle(.plain)
                                
                                if index < btManager.detectedDevices.count - 1 {
                                    Divider()
                                        .padding(.leading, 60) // align divider line with the start of text
                                }
                            }
                        }
                        .background(DesignSystem.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                    
                    // DEVICE COUNT
                    if btManager.detectedDevices.count == 1 {
                        Text("1 Device Found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.bottom, 120) // Leave space for bottom bar
                    } else {
                        (Text("\(btManager.detectedDevices.count)") + Text(" ") + Text("Devices Found"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.bottom, 120) // Leave space for bottom bar
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 16) {
                    Button {
                        if btManager.isScanning {
                            btManager.continueScanInBackground = false
                            btManager.stopScanning()
                            dismiss()
                        } else if !btManager.detectedDevices.isEmpty {
                            navigateToAllResults = true
                        } else {
                            btManager.startScanning()
                        }
                    } label: {
                        Group {
                            if btManager.isScanning {
                                Text("Stop Scanning")
                            } else if !btManager.detectedDevices.isEmpty {
                                Text("View All Results")
                            } else {
                                Text("Try Again")
                            }
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(DesignSystem.heroBackground)
                        )
                        .overlay(
                            Capsule()
                                .stroke(DesignSystem.primaryBlue.opacity(0.6), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
                .padding(.top, 16)
                .background(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: DesignSystem.backgroundColor, location: 0.5),
                            .init(color: DesignSystem.backgroundColor, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    DeviceFiltersSettingsView()
                } label: {
                    Image("Slider_03")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            handleScanOnAppear()
        }
        .onDisappear {
            if !btManager.continueScanInBackground {
                btManager.stopScanning()
            }
        }
        .navigationDestination(isPresented: $navigateToAllResults) {
            AllResultsView()
        }
        .navigationDestination(item: $selectedDevice) { device in
            // Map the transient BluetoothDevice to a temporary DetectedDevice for the details view
            let tempDevice = DetectedDevice(
                deviceId: device.deviceId,
                name: device.name,
                type: device.type,
                timestamp: device.lastSeen,
                rssi: device.rssi,
                isStarred: device.isStarred || TrustedDeviceManager.shared.isTrusted(id: device.deviceId),
                threatLevel: device.threatLevel,
                isSimulated: device.isSimulated,
                companyID: device.companyID,
                manufacturer: device.manufacturer
            )
            DeviceDetailView(device: tempDevice)
        }
    }
    
    private func handleScanOnAppear() {
        btManager.startScanning()
    }
    
    private func toggleScanningWithLocationCheck() {
        if btManager.isScanning {
            btManager.continueScanInBackground = false
            btManager.stopScanning()
        } else {
            btManager.startScanning()
        }
    }
    
    private func deviceRowCard(for device: BluetoothDevice) -> some View {
        let isTrusted = TrustedDeviceManager.shared.isTrusted(id: device.deviceId)
        
        return HStack(spacing: 16) {
            DeviceRowView(
                name: device.name,
                type: device.type,
                manufacturer: device.manufacturer,
                rssi: device.rssi,
                isStarred: device.isStarred || isTrusted,
                isTrusted: isTrusted,
                timestamp: nil,
                estimatedDistance: device.estimatedDistance
            )
            
            Spacer()
            
            // Trailing Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
