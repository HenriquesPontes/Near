//
//  DevicePingNode.swift
//  Near
//
//  Created by Admin on 6/3/26.
//

import SwiftUI

struct DevicePingNode: View {
    let device: BluetoothDevice
    let action: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var color: Color {
        switch device.type {
        case "rayban_meta": return .red
        case "vision_pro": return .purple
        case "snap_spectacles": return .yellow
        case "google_glass": return .green
        case "samsung_glasses": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer Pulse Ring
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 32, height: 32)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            pulseScale = 1.6
                            pulseOpacity = 0.0
                        }
                    }
                
                // Glowing Core
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: color, radius: 6)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(device.name) on radar")
        .accessibilityHint("Double tap to select this device")
    }
}

#Preview {
    DevicePingNode(device: BluetoothDevice(deviceId: "1", name: "Rayban Meta", type: "rayban_meta", rssi: -60)) {}
        .padding()
        .background(Color.black)
}
